import SQLyra
import XCTest

final class DatabaseTests: XCTestCase {
    private let fileManager = FileManager.default
    private let path = "Tests/new.db"

    override func setUp() {
        super.setUp()
        #if Xcode  // for relative path
        fileManager.changeCurrentDirectoryPath(#file.components(separatedBy: "/Tests")[0])
        #endif
    }

    func testOpen() throws {
        let url = URL(fileURLWithPath: path)
        let database = try Database.open(at: path, options: [.readwrite, .create])
        defer {
            XCTAssertNoThrow(try fileManager.removeItem(at: url))
        }
        XCTAssertFalse(database.isReadonly)
        XCTAssertEqual(database.path, url.path)
        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
    }

    func testOpenError() {
        XCTAssertThrowsError(try Database.open(at: path, options: [])) { err in
            guard let error = err as? DatabaseError else {
                return XCTFail("Unexpected error: \(err)")
            }
            XCTAssertEqual(error.code, 21)  // SQLITE_MISUSE
            XCTAssertEqual(error.message, "bad parameter or other API misuse")
            XCTAssertEqual(error.reason, "flags must include SQLITE_OPEN_READONLY or SQLITE_OPEN_READWRITE")
        }
    }

    func testPathInMemory() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])
        XCTAssertEqual(database.path, "")
    }

    func testExecute() throws {
        let database = try Database.open(at: path, options: [.readwrite, .memory])

        try database.execute("CREATE TABLE contacts(id INT PRIMARY KEY NOT NULL, name CHAR(255));")
        try database.execute("INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
        try database.execute("INSERT INTO contacts (id, name) VALUES (2, 'John');")

        var rows: [[String: String]] = []
        try database.execute("SELECT * FROM contacts;") { rows.append($0) }
        let expected = [
            ["id": "1", "name": "Paul"],
            ["id": "2", "name": "John"],
        ]
        XCTAssertEqual(rows, expected)
        // try database.execute("SELECT name FROM sqlite_master WHERE type ='table';")
    }
}
