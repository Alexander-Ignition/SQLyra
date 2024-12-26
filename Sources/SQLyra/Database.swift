import SQLite3

/// SQLite database.
public final class Database: DatabaseHandle {

    public struct OpenOptions: OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static var readonly: OpenOptions { .init(SQLITE_OPEN_READONLY) }
        public static var readwrite: OpenOptions { .init(SQLITE_OPEN_READWRITE) }
        public static var create: OpenOptions { .init(SQLITE_OPEN_CREATE) }
        public static var uri: OpenOptions { .init(SQLITE_OPEN_URI) }
        public static var memory: OpenOptions { .init(SQLITE_OPEN_MEMORY) }
        public static var noMutex: OpenOptions { .init(SQLITE_OPEN_NOMUTEX) }
        public static var fullMutex: OpenOptions { .init(SQLITE_OPEN_FULLMUTEX) }
        public static var sharedCache: OpenOptions { .init(SQLITE_OPEN_SHAREDCACHE) }
        public static var privateCache: OpenOptions { .init(SQLITE_OPEN_PRIVATECACHE) }
    }

    /// SQLite db handle.
    private(set) var db: OpaquePointer!

    /// Absolute path to database file.
    public var path: String { sqlite3_db_filename(db, nil).string ?? "" }

    /// Determine if a database is read-only.
    ///
    /// - SeeAlso: `OpenOptions.readonly`.
    public var isReadonly: Bool { sqlite3_db_readonly(db, nil) == 1 }

    /// Opening a new database connection.
    ///
    /// - Parameters:
    ///   - path: Relative or absolute path to the database file.
    ///   - options: Database open options.
    /// - Returns: A new database connection.
    /// - Throws: `DatabaseError`.
    public static func open(at path: String, options: OpenOptions = []) throws -> Database {
        let database = Database()

        let code = sqlite3_open_v2(path, &database.db, options.rawValue, nil)
        try database.check(code)

        return database
    }

    /// Use `Database.open(at:options:)`.
    private init() {}

    deinit {
        let code = sqlite3_close_v2(db)
        assert(code == SQLITE_OK, "sqlite3_close_v2(): \(code)")
    }

    /// Run multiple statements of SQL.
    ///
    /// - Parameter sql: statements.
    /// - Throws: `DatabaseError`.
    public func execute(_ sql: String) throws {
        let status = sqlite3_exec(db, sql, nil, nil, nil)
        try check(status)
    }

    /// Compiling an SQL statement.
    public func prepare(_ sql: String, _ parameters: SQLParameter?...) throws -> PreparedStatement {
        try prepare(sql, parameters: parameters)
    }

    /// Compiling an SQL statement.
    public func prepare(_ sql: String, parameters: [SQLParameter?]) throws -> PreparedStatement {
        var stmt: OpaquePointer!
        let code = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        try check(code)
        let statement = PreparedStatement(stmt: stmt)
        try statement.bind(parameters: parameters)
        return statement
    }
}
