import SQLite3
import SQLyra
import Testing

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
#else
import FoundationEssentials
#endif

extension Database.OpenOptions: CustomTestStringConvertible {
    public var testDescription: String {
        String(rawValue, radix: 16, uppercase: true)
    }
}

struct DatabaseTests {

    @Test(arguments: [
        (Database.OpenOptions.create, SQLITE_OPEN_CREATE),
        (Database.OpenOptions.readwrite, SQLITE_OPEN_READWRITE),
        (Database.OpenOptions.readonly, SQLITE_OPEN_READONLY),
        (Database.OpenOptions.memory, SQLITE_OPEN_MEMORY),
        (Database.OpenOptions.extendedResultCode, SQLITE_OPEN_EXRESCODE),
        (Database.OpenOptions.uri, SQLITE_OPEN_URI),
        (Database.OpenOptions.noFollow, SQLITE_OPEN_NOFOLLOW),
        (Database.OpenOptions.noMutex, SQLITE_OPEN_NOMUTEX),
        (Database.OpenOptions.fullMutex, SQLITE_OPEN_FULLMUTEX),
        (Database.OpenOptions.sharedCache, SQLITE_OPEN_SHAREDCACHE),
        (Database.OpenOptions.privateCache, SQLITE_OPEN_PRIVATECACHE),
    ])
    func open(options: Database.OpenOptions, expected: Int32) {
        #expect(options.rawValue == expected)
    }

    @Test func open() throws {
        let fileManager = FileManager.default
        try #require(fileManager.changeCurrentDirectoryPath(fileManager.temporaryDirectory.path))
        let url = URL(fileURLWithPath: "SQLyra.db", isDirectory: false)
        defer {
            // closing database before remove a file
            #expect(throws: Never.self) { try fileManager.removeItem(at: url) }
        }
        do {
            let database = try Database.open(at: "SQLyra.db", options: [.readwrite, .create])
            #expect(!database.isReadonly)
            #expect(database.filename == url.path)
            #expect(fileManager.fileExists(atPath: url.path))
        }
    }

    @Test func openError() {
        #expect(throws: DatabaseError.self) {
            try Database.open(at: "db.sqlite", options: [])
        }
    }

    @Test func memory() throws {
        let database = try Database.open(at: ":memory:", options: [.readwrite, .memory])
        #expect(!database.isReadonly)
        #expect(database.filename == "")
    }

    @Test func readonly() throws {
        let database = try Database.open(at: ":memory:", options: [.readonly, .memory])
        #expect(database.isReadonly)
        #expect(database.filename == "")
    }

    @Test func execute() throws {
        let database = try Database.open(at: ":memory:", options: [.readwrite, .memory])

        let sql = """
            CREATE TABLE contacts(id INT PRIMARY KEY NOT NULL, name TEXT);
            INSERT INTO contacts (id, name) VALUES (1, 'Paul');
            INSERT INTO contacts (id, name) VALUES (2, 'John');
            """
        try database.execute(sql)

        struct Contact: Codable, Equatable {
            let id: Int
            let name: String
        }
        let contacts = try database.prepare("SELECT * FROM contacts;").array(Contact.self)
        let expected = [
            Contact(id: 1, name: "Paul"),
            Contact(id: 2, name: "John"),
        ]
        #expect(contacts == expected)
    }

    struct ErrorCodes {

        @Test func defaults() throws {
            let database = try Database.open(at: ":memory:", options: [.readwrite, .memory])
            try expect(errorCode: SQLITE_CONSTRAINT, database)
        }

        @Test func extendedResultCodeOption() throws {
            let database = try Database.open(at: ":memory:", options: [.readwrite, .memory, .extendedResultCode])
            try expect(errorCode: 1299, database)
        }

        @Test func setExtendedResultCodesEnabled() throws {
            let database = try Database.open(at: ":memory:", options: [.readwrite, .memory])
            database.setExtendedResultCodesEnabled(true)
            try expect(errorCode: 1299, database)
        }

        @Test func setExtendedResultCodesDisabled() throws {
            let database = try Database.open(at: ":memory:", options: [.readwrite, .memory, .extendedResultCode])
            database.setExtendedResultCodesEnabled(false)
            try expect(errorCode: SQLITE_CONSTRAINT, database)
        }

        private func expect(errorCode: Int32, _ database: Database) throws {
            try database.execute("CREATE TABLE employees (id INT PRIMARY KEY NOT NULL, name TEXT);")

            let error = #expect(throws: DatabaseError.self) {
                try database.execute("INSERT INTO employees (name) VALUES ('John');")
            }
            #expect(error?.code == errorCode)
            #expect(error?.codeDescription == "constraint failed")
            #expect(error?.message == "NOT NULL constraint failed: employees.id")

            #expect(database.errorCode == errorCode)
            #expect(database.extendedErrorCode == 1299)  // SQLITE_CONSTRAINT_NOTNULL
            #expect(database.errorMessage == "NOT NULL constraint failed: employees.id")
        }
    }
}
