import Foundation
import SQLyra
import Testing

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
        let database = try Database.open(at: path, options: [.readwrite, .create])
        defer {
            #expect(throws: Never.self) { try fileManager.removeItem(at: url) }
        }
        #expect(!database.isReadonly)
        #expect(database.path == url.path)
        #expect(fileManager.fileExists(atPath: url.path))
    }

    @Test func openError() {
        let error = DatabaseError(
            code: 21,  // SQLITE_MISUSE
            message: "bad parameter or other API misuse",
            reason: "flags must include SQLITE_OPEN_READONLY or SQLITE_OPEN_READWRITE"
        )
        #expect(throws: error) {
            try Database.open(at: path, options: [])
        }
    }

    @Test func pathInMemory() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])
        #expect(database.path == "")
    }

    @Test func execute() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])

        try database.execute("CREATE TABLE contacts(id INT PRIMARY KEY NOT NULL, name TEXT);")
        try database.execute("INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
        try database.execute("INSERT INTO contacts (id, name) VALUES (2, 'John');")

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
