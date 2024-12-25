import SQLite3

/// SQLite database error.
public struct DatabaseError: Error, Equatable, Hashable {
    /// Failed result code.
    public let code: Int32

    /// A short error description.
    public var message: String

    /// A complete sentence (or more) describing why the operation failed.
    public let reason: String

    /// A new database error.
    ///
    /// - Parameters:
    ///   - code: failed result code.
    ///   - message: A short error description.
    ///   - reason: A complete sentence (or more) describing why the operation failed.
    public init(code: Int32, message: String, reason: String) {
        self.code = code
        self.message = message
        self.reason = reason
    }

    init(code: Int32, database: Database) {
        self.init(code: code, db: database.db)
    }

    init(code: Int32, statement: PreparedStatement) {
        self.init(code: code, db: statement.db)
    }

    private init(code: Int32, db: OpaquePointer?) {
        self.code = code
        self.message = sqlite3_errstr(code).string ?? ""
        self.reason = sqlite3_errmsg(db).string ?? ""
    }
}
