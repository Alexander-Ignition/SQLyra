// snippet.hide
import Foundation
// snippet.show
import SQLyra

// snippet.hide
struct WorkingDirectory: ~Copyable {
    private let fileManager = FileManager.default

    deinit {
        try? removeDatabase()
    }

    func prepare() throws {
        if !fileManager.currentDirectoryPath.hasSuffix("Snippets") {
            precondition(fileManager.changeCurrentDirectoryPath("Snippets/"), "couldn't change directory")
        }
        print("currentDirectoryPath:", fileManager.currentDirectoryPath)
        try removeDatabase()
    }

    func removeDatabase() throws {
        try removeFile(path: "db.sqlite")
    }

    func removeFile(path: String) throws {
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
    }
}

let workingDirectory = WorkingDirectory()
try workingDirectory.prepare()

// snippet.show
let database = try Database.open(
    at: "db.sqlite",
    options: [.create, .readwrite]
)

let schema = """
    CREATE TABLE IF NOT EXISTS contacts(
        id INT PRIMARY KEY NOT NULL,
        name TEXT
    );
    """
try database.execute(schema)

let insert = try database.prepare(
    "INSERT INTO contacts (id, name) VALUES (?, ?);"
)
try insert.bind(parameters: 1, "Paul")
try insert.execute()
try insert.bind(parameters: 2, "John")
try insert.execute()

struct Contact: Codable {
    let id: Int
    let name: String?
}

let contacts = try database.prepare("SELECT * FROM contacts;").array(Contact.self)
print(contacts)
// [GettingStarted.Contact(id: 1, name: Optional("Paul")), GettingStarted.Contact(id: 2, name: Optional("John"))]

// snippet.hide
try workingDirectory.removeDatabase()
