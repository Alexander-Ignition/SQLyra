import Foundation
import SQLite3

/// Compiled SQL statement.
///
/// To execute an SQL statement, it must first be compiled into a byte-code program using one of these routines.
/// Or, in other words, these routines are constructors for the prepared statement object.
public final class PreparedStatement: DatabaseHandle {
    @usableFromInline
    let stmt: OpaquePointer

    /// Find the database handle of a prepared statement.
    var db: OpaquePointer! { sqlite3_db_handle(stmt) }

    init(stmt: OpaquePointer) {
        self.stmt = stmt
    }

    deinit {
        let code = sqlite3_finalize(stmt)
        assert(code == SQLITE_OK, "sqlite3_finalize(): \(code)")
    }

    /// Evaluate an SQL statement.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func execute() throws -> PreparedStatement {
        try check(sqlite3_step(stmt), SQLITE_DONE)
    }

    /// The new row of data is ready for processing.
    ///
    /// - Throws: ``DatabaseError``
    public func step() throws -> Bool {
        switch sqlite3_step(stmt) {
        case SQLITE_DONE:
            return false
        case SQLITE_ROW:
            return true
        case let code:
            throw DatabaseError(code: code, db: db)
        }
    }

    /// Reset the prepared statement.
    ///
    /// The ``PreparedStatement/reset()`` function is called to reset a prepared statement object back to its initial state, ready to be re-executed.
    /// Any SQL statement variables that had values bound to them using the `bind()` API retain their values.
    /// Use ``PreparedStatement/clearBindings()`` to reset the bindings.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func reset() throws -> PreparedStatement {
        try check(sqlite3_reset(stmt))
    }

    /// Reset all bindings on a prepared statement.
    ///
    /// Contrary to the intuition of many, ``PreparedStatement/reset()`` does not reset the bindings on a prepared statement.
    /// Use this routine to reset all host parameters to NULL.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func clearBindings() throws -> PreparedStatement {
        try check(sqlite3_clear_bindings(stmt))
    }

    // MARK: - Decodable

    public func array<T>(decoding type: T.Type) throws -> [T] where T: Decodable {
        var array: [T] = []
        while try step() {
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
            Data(bytes: bytes, count: Int(sqlite3_column_bytes(stmt, index)))
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

// MARK: - Retrieving Statement SQL

extension PreparedStatement {
    /// SQL text used to create prepared statement.
    public var sql: String { sqlite3_sql(stmt).string ?? "" }

    /// UTF-8 string containing the normalized SQL text of prepared statement.
    ///
    /// The semantics used to normalize a SQL statement are unspecified and subject to change.
    /// At a minimum, literal values will be replaced with suitable placeholders.
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public var normalizedSQL: String { sqlite3_normalized_sql(stmt).string ?? "" }

    /// SQL text of prepared statement with bound parameters expanded.
    public var expandedSQL: String {
        guard let pointer = sqlite3_expanded_sql(stmt) else { return "" }
        defer { sqlite3_free(pointer) }
        return String(cString: pointer)
    }
}

// MARK: - SQL Parameters

extension PreparedStatement {
    /// Number of SQL parameters.
    public var parameterCount: Int32 { sqlite3_bind_parameter_count(stmt) }

    /// Name of a SQL parameter.
    public func parameterName(at index: Int32) -> String? {
        sqlite3_bind_parameter_name(stmt, index).map { String(cString: $0) }
    }

    /// Index of a parameter with a given name.
    public func parameterIndex(for name: String) -> Int32 {
        sqlite3_bind_parameter_index(stmt, name)
    }
}

// MARK: - Bind SQL Parameters

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension PreparedStatement {
    @discardableResult
    public func bind(name: String, _ parameter: SQLParameter?) throws -> PreparedStatement {
        try bind(index: parameterIndex(for: name), parameter)
    }

    @discardableResult
    public func bind(index: Int32, _ parameter: SQLParameter?) throws -> PreparedStatement {
        var code = SQLITE_OK
        switch parameter {
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
        return try check(code)
    }

    @discardableResult
    public func bind(index: Int32, int64: Int64) throws -> PreparedStatement {
        try check(sqlite3_bind_int64(stmt, index, int64))
    }

    @discardableResult
    public func bind(index: Int32, double: Double) throws -> PreparedStatement {
        try check(sqlite3_bind_double(stmt, index, double))
    }

    @discardableResult
    public func bind(name: String, string: String) throws -> PreparedStatement {
        try bind(index: parameterIndex(for: name), string: string)
    }

    @discardableResult
    public func bind(index: Int32, string: String) throws -> PreparedStatement {
        try check(sqlite3_bind_text(stmt, index, string, -1, SQLITE_TRANSIENT))
    }

    @discardableResult
    public func bind(index: Int32, data: Data) throws -> PreparedStatement {
        let code = data.withUnsafeBytes { ptr in
            sqlite3_bind_blob(stmt, index, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
        }
        return try check(code)
    }
}

// MARK: - Columns

extension PreparedStatement {
    /// Number of columns in a `PreparedStatement`.
    public var columnCount: Int32 { sqlite3_column_count(stmt) }

    public func columnName(at index: Int32) -> String? {
        sqlite3_column_name(stmt, index).string
    }

    var columnIndexByName: [String: Int32] {
        [String: Int32](
            uniqueKeysWithValues: (0..<columnCount).compactMap { index in
                columnName(at: index).map { name in (name, index) }
            }
        )
    }
}

// MARK: - Result values from a Query

extension PreparedStatement {

    public func columnString(at index: Int32) -> String? {
        sqlite3_column_text(stmt, index).flatMap { String(cString: $0) }
    }

    public func columnInt64(at index: Int32) -> Int64 {
        sqlite3_column_int64(stmt, index)
    }

    public func columnDouble(at index: Int32) -> Double {
        sqlite3_column_double(stmt, index)
    }

    public func columnBlob(at index: Int32) -> Data? {
        sqlite3_column_blob(stmt, index).map { bytes in
            Data(bytes: bytes, count: Int(sqlite3_column_bytes(stmt, index)))
        }
    }

    public func columnNull(at index: Int32) -> Bool {
        sqlite3_column_type(stmt, index) == SQLITE_NULL
    }
}

// MARK: - CustomStringConvertible

extension PreparedStatement: CustomStringConvertible {
    public var description: String {
        #"PreparedStatement(sql: "\#(sql)")"#
    }
}

// MARK: - CustomDebugStringConvertible

extension PreparedStatement: CustomDebugStringConvertible {
    public var debugDescription: String {
        #"PreparedStatement(expandedSQL: "\#(expandedSQL)")"#
    }
}
