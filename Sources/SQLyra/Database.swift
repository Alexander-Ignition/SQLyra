import SQLite3

/// SQLite database.
public final class Database {
    /// Database open options.
    public struct OpenOptions: OptionSet, Sendable {
        /// SQLite flags for opening a database connection.
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        // MARK: - Required

        /// The database  is created if it does not already exist.
        public static let create = OpenOptions(rawValue: SQLITE_OPEN_CREATE)

        /// The database is opened for reading and writing if possible, or reading only if the file is write protected by the operating system.
        ///
        /// In either case the database must already exist, otherwise an error is returned. For historical reasons,
        /// if opening in read-write mode fails due to OS-level permissions, an attempt is made to open it in read-only mode.
        public static let readwrite = OpenOptions(rawValue: SQLITE_OPEN_READWRITE)

        /// The database is opened in read-only mode. If the database does not already exist, an error is returned.
        public static let readonly = OpenOptions(rawValue: SQLITE_OPEN_READONLY)

        // MARK: - Addition

        /// The database will be opened as an in-memory database.
        ///
        /// The database is named by the "filename" argument for the purposes of cache-sharing,
        /// if shared cache mode is enabled, but the "filename" is otherwise ignored.
        public static let memory = OpenOptions(rawValue: SQLITE_OPEN_MEMORY)

        /// The database connection comes up in "extended result code mode".
        public static let extendedResultCode = OpenOptions(rawValue: SQLITE_OPEN_EXRESCODE)

        /// The filename can be interpreted as a URI if this flag is set.
        public static let uri = OpenOptions(rawValue: SQLITE_OPEN_URI)

        /// The database filename is not allowed to contain a symbolic link.
        public static let noFollow = OpenOptions(rawValue: SQLITE_OPEN_NOFOLLOW)

        // MARK: - Threading modes

        /// The new database connection will use the "multi-thread" threading mode.
        ///
        /// This means that separate threads are allowed to use SQLite at the same time, as long as each thread is using a different database connection.
        ///
        /// [Using SQLite in multi-threaded Applications](https://www.sqlite.org/threadsafe.html)
        public static let noMutex = OpenOptions(rawValue: SQLITE_OPEN_NOMUTEX)

        /// The new database connection will use the "serialized" threading mode.
        ///
        /// This means the multiple threads can safely attempt to use the same database connection at the same time.
        /// (Mutexes will block any actual concurrency, but in this mode there is no harm in trying.)
        ///
        /// [Using SQLite in multi-threaded Applications](https://www.sqlite.org/threadsafe.html)
        public static let fullMutex = OpenOptions(rawValue: SQLITE_OPEN_FULLMUTEX)

        // MARK: - Cache modes

        /// The database is opened shared cache enabled.
        ///
        /// - Warning: The use of shared cache mode is discouraged and hence shared cache capabilities may be omitted
        ///            from many builds of SQLite. In such cases, this option is a no-op.
        ///
        /// [SQLite Shared-Cache mode](https://www.sqlite.org/sharedcache.html)
        public static let sharedCache = OpenOptions(rawValue: SQLITE_OPEN_SHAREDCACHE)

        /// The database is opened shared cache disabled.
        ///
        /// [SQLite Shared-Cache mode](https://www.sqlite.org/sharedcache.html)
        public static let privateCache = OpenOptions(rawValue: SQLITE_OPEN_PRIVATECACHE)
    }

    /// SQLite db handle.
    private(set) var db: OpaquePointer!

    /// Return the filename for a database connection.
    ///
    /// If database is a temporary or in-memory database, then this function will return either a nil or an empty string.
    /// - SeeAlso: ``Database/OpenOptions/memory``
    public var filename: String? { sqlite3_db_filename(db, nil).string }

    /// Determine if a database is read-only.
    ///
    /// - SeeAlso: ``Database/OpenOptions/readonly``
    public var isReadonly: Bool { sqlite3_db_readonly(db, nil) == 1 }

    /// Opening a new database connection.
    ///
    /// - Parameters:
    ///   - filename: Relative or absolute path to the database file.
    ///   - options: The options parameter must include, at a minimum, one of the following three option combinations:
    ///   ``Database/OpenOptions/readonly``, ``Database/OpenOptions/readwrite``, ``Database/OpenOptions/create``.
    /// - Returns: A new database connection.
    /// - Throws: ``DatabaseError``
    public static func open(at filename: String, options: OpenOptions = []) throws -> Database {
        let database = Database()
        let code = sqlite3_open_v2(filename, &database.db, options.rawValue, nil)
        return try database.check(code)
    }

    /// Use ``Database/open(at:options:)``.
    private init() {}

    deinit {
        let code = sqlite3_close_v2(db)
        assert(code == SQLITE_OK, "sqlite3_close_v2(): \(code)")
    }

    /// One-step query execution Interface.
    ///
    /// The convenience wrapper around ``Database/prepare(_:)`` and ``PreparedStatement``,
    /// that allows an application to run multiple statements of SQL without having to use a lot code.
    ///
    /// - Parameter sql: UTF-8 encoded, semicolon-separate SQL statements to be evaluated.
    /// - Throws: ``DatabaseError``
    public func execute(_ sql: String) throws {
        try check(sqlite3_exec(db, sql, nil, nil, nil))
    }

    /// Compiling an SQL statement.
    ///
    /// To execute an SQL statement, it must first be compiled into a byte-code program using one of these routines.
    /// Or, in other words, these routines are constructors for the prepared statement object.
    ///
    /// - Parameter sql: The statement to be compiled, encoded as UTF-8.
    /// - Returns: A compiled prepared statement that can be executed.
    /// - Throws: ``DatabaseError``
    public func prepare(_ sql: String) throws -> PreparedStatement {
        var stmt: OpaquePointer!
        try check(sqlite3_prepare_v2(db, sql, -1, &stmt, nil))
        return PreparedStatement(stmt: stmt, database: self)
    }
}
