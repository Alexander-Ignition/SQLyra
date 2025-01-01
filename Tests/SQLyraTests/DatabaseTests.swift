import Foundation
import SQLite3
import SQLyra
import Testing

@Test func openOptionsRawValue() {
    typealias Options = Database.OpenOptions

    #expect(Options.create.rawValue == SQLITE_OPEN_CREATE)
    #expect(Options.readwrite.rawValue == SQLITE_OPEN_READWRITE)
    #expect(Options.readonly.rawValue == SQLITE_OPEN_READONLY)
    #expect(Options.memory.rawValue == SQLITE_OPEN_MEMORY)
    #expect(Options.extendedResultCode.rawValue == SQLITE_OPEN_EXRESCODE)
    #expect(Options.uri.rawValue == SQLITE_OPEN_URI)
    #expect(Options.noFollow.rawValue == SQLITE_OPEN_NOFOLLOW)
    #expect(Options.noMutex.rawValue == SQLITE_OPEN_NOMUTEX)
    #expect(Options.fullMutex.rawValue == SQLITE_OPEN_FULLMUTEX)
    #expect(Options.sharedCache.rawValue == SQLITE_OPEN_SHAREDCACHE)
    #expect(Options.privateCache.rawValue == SQLITE_OPEN_PRIVATECACHE)
}

struct DatabaseTests {
    private let fileManager = FileManager.default
    private let path = "Tests/new.db"

    init() {
        #if Xcode  // for relative path
        fileManager.changeCurrentDirectoryPath(#file.components(separatedBy: "/Tests")[0])
        #endif
    }

    @Test func open() throws {
        let url = URL(fileURLWithPath: path)
        var database: Database! = try Database.open(at: path, options: [.readwrite, .create])
        defer {
            database = nil  // closing before remove a file
            #expect(throws: Never.self) { try fileManager.removeItem(at: url) }
        }
        #expect(!database.isReadonly)
        #expect(database.filename == url.path)
        #expect(fileManager.fileExists(atPath: url.path))
    }

    @Test func openError() {
        let error = DatabaseError(
            code: SQLITE_MISUSE,
            message: "bad parameter or other API misuse",
            details: "flags must include SQLITE_OPEN_READONLY or SQLITE_OPEN_READWRITE"
        )
        #expect(throws: error) {
            try Database.open(at: path, options: [])
        }
    }

    @Test func memory() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])
        #expect(!database.isReadonly)
        #expect(database.filename == "")
    }

    @Test func readonly() throws {
        let database = try Database.open(at: path, options: [.readonly, .memory])
        #expect(database.isReadonly)
        #expect(database.filename == "")
    }

    @Test func execute() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])

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
        let contacts = try database.prepare("SELECT * FROM contacts;").array(decoding: Contact.self)
        let expected = [
            Contact(id: 1, name: "Paul"),
            Contact(id: 2, name: "John"),
        ]
        #expect(contacts == expected)
        // try database.execute("SELECT name FROM sqlite_master WHERE type ='table';")
    }
}
