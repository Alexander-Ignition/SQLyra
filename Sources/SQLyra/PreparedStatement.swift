import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public final class PreparedStatement {
    private let stmt: OpaquePointer

    /// Find the database handle of a prepared statement.
    var db: OpaquePointer? { sqlite3_db_handle(stmt) }

    public let columnIndexByName: [String: Int32]

    /// Number of columns in a `PreparedStatement`.
    public var columnCount: Int32 { sqlite3_column_count(stmt) }

    public var columnNames: [String] {
        (0..<columnCount).map { String(cString: sqlite3_column_name(stmt, $0)) }
    }

    /// Retrieving statement SQL.
    public var sql: String { sqlite3_sql(stmt).string ?? "" }

    @available(macOS 12.0, *)
    public var normalizedSQL: String { sqlite3_normalized_sql(stmt).string ?? "" }

    /// Retrieving statement SQL with parameters.
    public var expandedSQL: String {
        guard let pointer = sqlite3_expanded_sql(stmt) else { return "" }
        defer { sqlite3_free(pointer) }
        return String(cString: pointer)
    }

    init(stmt: OpaquePointer) {
        self.stmt = stmt

        let count: Int32 = sqlite3_column_count(stmt)
        var columns = [String: Int32](minimumCapacity: Int(count))
        for index in 0..<count {
            let name = String(cString: sqlite3_column_name(stmt, index))
            columns[name] = index
        }
        self.columnIndexByName = columns
    }

    deinit {
        let code = sqlite3_finalize(stmt)
        assert(code == SQLITE_OK, "sqlite3_finalize(): \(code)")
    }

    private func check(_ code: Int32, _ success: Int32 = SQLITE_OK) throws {
        if code != success {
            throw DatabaseError(code: code, statement: self)
        }
    }

    /// Reset the prepared statement.
    public func reset() throws {
        let code = sqlite3_reset(stmt)
        try check(code)
    }

    /// Reset all bindings on a prepared statement.
    public func clear() throws {
        let code = sqlite3_clear_bindings(stmt)
        try check(code)
    }

    /// Evaluate an SQL statement.
    public func evaluate() throws {
        let code = sqlite3_step(stmt)
        try check(code, SQLITE_DONE)
    }

    public func next() throws -> Bool {
        let code = sqlite3_step(stmt)

        switch code {
        case SQLITE_DONE:
            return false
        case SQLITE_ROW:
            return true
        default:
            throw DatabaseError(code: code, statement: self)
        }
    }

    // MARK: - SQL Parameters

    public func bind(parameters: [SQLParameter?]) throws {
        for (offset, param) in parameters.enumerated() {
            let index = Int32(offset + 1)
            var code = SQLITE_OK

            switch param {
            case .none:
                code = sqlite3_bind_null(stmt, index)
            case .int64(let number)?:
                code = sqlite3_bind_int64(stmt, index, number)
            case .double(let double)?:
                code = sqlite3_bind_double(stmt, index, double)
            case .text(let string)?:
                code = sqlite3_bind_text(stmt, index, string, -1, SQLITE_TRANSIENT)
            case .blob(let data)?:
                code = data.withUnsafeBytes { ptr in
                    sqlite3_bind_blob(stmt, index, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
                }
            }
            try check(code)
        }
    }

    // MARK: - Decodable

    public func array<T>(decoding type: T.Type) throws -> [T] where T: Decodable {
        var array: [T] = []
        while try next() {
            let value = try decode(type)
            array.append(value)
        }
        return array
    }

    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try StatementDecoder().decode(type, from: self)
    }

    // MARK: - String

    public func string(at index: Int32) -> String? {
        sqlite3_column_text(stmt, index).map { String(cString: $0) }
    }

    public func string(for name: String) -> String? {
        columnIndexByName[name].flatMap { string(at: $0) }
    }

    // MARK: - Int64

    public func int64(at index: Int32) -> Int64 {
        sqlite3_column_int64(stmt, index)
    }

    public func int64(for name: String) -> Int64? {
        columnIndexByName[name].map { int64(at: $0) }
    }

    // MARK: - Double

    public func double(at index: Int32) -> Double {
        sqlite3_column_double(stmt, index)
    }

    public func double(for name: String) -> Double? {
        columnIndexByName[name].map { double(at: $0) }
    }

    // MARK: - Blob

    public func blob(at index: Int32) -> Data? {
        sqlite3_column_blob(stmt, index).map { bytes in
            let count = sqlite3_column_bytes(stmt, index)
            return Data(bytes: bytes, count: Int(count))
        }
    }

    // MARK: - Null

    public func null(at index: Int32) -> Bool {
        sqlite3_column_type(stmt, index) == SQLITE_NULL
    }

    public func null(for name: String) -> Bool {
        columnIndexByName[name].map { null(at: $0) } ?? true
    }
}

// MARK: - CustomStringConvertible

extension PreparedStatement: CustomStringConvertible {
    public var description: String {
        "PreparedStatement(sql: \"\(sql)\")"
    }
}

extension PreparedStatement: CustomDebugStringConvertible {
    public var debugDescription: String {
        "PreparedStatement(expandedSQL: \"\(expandedSQL)\")"
    }
}
