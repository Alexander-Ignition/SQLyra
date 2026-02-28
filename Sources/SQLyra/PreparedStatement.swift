import SQLite3

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
#else
import FoundationEssentials
#endif

/// Compiled SQL statement.
///
/// To execute an SQL statement, it must first be compiled into a byte-code program using one of these routines.
/// Or, in other words, these routines are constructors for the prepared statement object.
public final class PreparedStatement {
    let stmt: OpaquePointer
    let database: Database  // release database after all statements

    private(set) lazy var columnIndexByName = [String: Int](
        uniqueKeysWithValues: (0..<columnCount).compactMap { index in
            columnName(at: index).map { name in (name, index) }
        }
    )

    init(stmt: OpaquePointer, database: Database) {
        self.stmt = stmt
        self.database = database
    }

    deinit {
        let code = sqlite3_finalize(stmt)
        assert(code == SQLITE_OK, "sqlite3_finalize(): \(code)")
    }

    private func check(_ code: Int32, _ success: Int32 = SQLITE_OK) throws(DatabaseError) -> PreparedStatement {
        try database.check(code, success)
        return self
    }

    /// Evaluate an SQL statement.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func execute() throws(DatabaseError) -> PreparedStatement {
        defer { _reset() }
        return try check(sqlite3_step(stmt), SQLITE_DONE)
    }

    /// Reset the prepared statement.
    ///
    /// The ``PreparedStatement/reset()`` function is called to reset a prepared statement object back to its initial state, ready to be re-executed.
    /// Any SQL statement variables that had values bound to them using the `bind()` API retain their values.
    /// Use ``PreparedStatement/clearBindings()`` to reset the bindings.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func reset() throws(DatabaseError) -> PreparedStatement {
        try check(sqlite3_reset(stmt))
    }

    /// clear error state and prepare for reuse
    func _reset() {
        sqlite3_reset(stmt)
    }
}

// MARK: - Retrieving Statement SQL

extension PreparedStatement {
    /// SQL text used to create prepared statement.
    public var sql: String { sqlite3_sql(stmt).string ?? "" }

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    /// UTF-8 string containing the normalized SQL text of prepared statement.
    ///
    /// The semantics used to normalize a SQL statement are unspecified and subject to change.
    /// At a minimum, literal values will be replaced with suitable placeholders.
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public var normalizedSQL: String { sqlite3_normalized_sql(stmt).string ?? "" }
    #endif

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
    public var parameterCount: Int { Int(sqlite3_bind_parameter_count(stmt)) }

    /// Name of a SQL parameter.
    public func parameterName(at index: Int) -> String? {
        sqlite3_bind_parameter_name(stmt, Int32(index)).map { String(cString: $0) }
    }

    /// Index of a parameter with a given name.
    public func parameterIndex(for name: String) -> Int {
        Int(sqlite3_bind_parameter_index(stmt, name))
    }
}

// MARK: - Binding values

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension PreparedStatement {
    @discardableResult
    public func bind(name: String, parameter: SQLParameter) throws(DatabaseError) -> PreparedStatement {
        try bind(index: parameterIndex(for: name), parameter: parameter)
    }

    @discardableResult
    public func bind(parameters: SQLParameter...) throws(DatabaseError) -> PreparedStatement {
        for (index, parameter) in parameters.enumerated() {
            try bind(index: index + 1, parameter: parameter)
        }
        return self
    }

    @discardableResult
    public func bind(index: Int, parameter: SQLParameter) throws(DatabaseError) -> PreparedStatement {
        let index = Int32(index)
        let code =
            switch parameter {
            case .null:
                sqlite3_bind_null(stmt, index)
            case .int64(let number):
                sqlite3_bind_int64(stmt, index, number)
            case .double(let double):
                sqlite3_bind_double(stmt, index, double)
            case .text(let string):
                sqlite3_bind_text(stmt, index, string, -1, SQLITE_TRANSIENT)
            case .blob(let data):
                data.withUnsafeBytes { ptr in
                    sqlite3_bind_blob(stmt, index, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
                }
            }
        return try check(code)
    }

    /// Reset all bindings on a prepared statement.
    ///
    /// Contrary to the intuition of many, ``PreparedStatement/reset()`` does not reset the bindings on a prepared statement.
    /// Use this routine to reset all host parameters to NULL.
    ///
    /// - Throws: ``DatabaseError``
    @discardableResult
    public func clearBindings() throws(DatabaseError) -> PreparedStatement {
        try check(sqlite3_clear_bindings(stmt))
    }
}

// MARK: - Columns

extension PreparedStatement {
    /// Return the number of columns in the result set.
    public var columnCount: Int { Int(sqlite3_column_count(stmt)) }

    /// Returns the name assigned to a specific column in the result set of the SELECT statement.
    ///
    /// The name of a result column is the value of the "AS" clause for that column, if there is an AS clause.
    /// If there is no AS clause then the name of the column is unspecified and may change from one release of SQLite to the next.
    public func columnName(at index: Int) -> String? {
        sqlite3_column_name(stmt, Int32(index)).string
    }

    func columnDeclaration(at index: Int) -> String? {
        sqlite3_column_decltype(stmt, Int32(index)).string
    }
}

// MARK: - Result values from a Query

extension PreparedStatement {
    /// The new row of data is ready for processing.
    ///
    /// - Throws: ``DatabaseError``
    public func row() throws(DatabaseError) -> Row? {
        switch sqlite3_step(stmt) {
        case SQLITE_DONE: nil
        case SQLITE_ROW: Row(statement: self)
        case let code: throw database.error(code: code)
        }
    }

    public func array<T>(_ type: T.Type) throws -> [T] where T: Decodable {
        try array(type, using: RowDecoder.default)
    }

    public func array<T>(_ type: T.Type, using decoder: RowDecoder) throws -> [T] where T: Decodable {
        defer { _reset() }
        var array: [T] = []
        while let row = try row() {
            let value = try row.decode(type, using: decoder)
            array.append(value)
        }
        return array
    }

    @dynamicMemberLookup
    public struct Row: ~Copyable {
        let statement: PreparedStatement

        public subscript(dynamicMember name: String) -> Value? {
            self[name]
        }

        public subscript(columnName: String) -> Value? {
            statement.columnIndexByName[columnName].flatMap { self[$0] }
        }

        public subscript(columnIndex: Int) -> Value? {
            statement.value(at: columnIndex)
        }

        public func decode<T>(_ type: T.Type, using decoder: RowDecoder? = nil) throws -> T where T: Decodable {
            try (decoder ?? RowDecoder.default).decode(type, from: self)
        }
    }

    func null(for columnName: String) -> Bool {
        guard let columnIndex = columnIndexByName[columnName] else {
            return true
        }
        return null(at: columnIndex)
    }

    private func null(at columnIndex: Int) -> Bool {
        sqlite3_column_type(stmt, Int32(columnIndex)) == SQLITE_NULL
    }

    func value(at columnIndex: Int) -> Value? {
        if null(at: columnIndex) {
            return nil
        }
        return Value(columnIndex: Int32(columnIndex), statement: self)
    }

    /// Result value from a query.
    public struct Value: ~Copyable {
        let columnIndex: Int32
        let statement: PreparedStatement
        private var stmt: OpaquePointer { statement.stmt }

        /// 64-bit INTEGER result.
        public var int64: Int64 { sqlite3_column_int64(stmt, columnIndex) }

        /// 32-bit INTEGER result.
        public var int32: Int32 { sqlite3_column_int(stmt, columnIndex) }

        /// A platform-specific integer.
        public var int: Int { Int(int64) }

        /// 64-bit IEEE floating point number.
        public var double: Double { sqlite3_column_double(stmt, columnIndex) }

        /// Size of a BLOB or a UTF-8 TEXT result in bytes.
        public var count: Int { Int(sqlite3_column_bytes(stmt, columnIndex)) }

        /// UTF-8 TEXT result.
        public var string: String? {
            sqlite3_column_text(stmt, columnIndex).flatMap { String(cString: $0) }
        }

        /// BLOB result.
        public var blob: Data? {
            sqlite3_column_blob(stmt, columnIndex).map { Data(bytes: $0, count: count) }
        }
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
