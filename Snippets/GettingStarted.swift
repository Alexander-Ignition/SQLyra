// snippet.hide
import Foundation
// snippet.show
import SQLyra

// snippet.hide
func prepareDirectory(fileManager: FileManager = .default) throws {
    if !fileManager.currentDirectoryPath.hasSuffix("Snippets") {
        precondition(fileManager.changeCurrentDirectoryPath("Snippets/"), "couldn't change directory")
    }
    print("currentDirectoryPath:", fileManager.currentDirectoryPath)
    if fileManager.fileExists(atPath: "db.sqlite") {
        try fileManager.removeItem(atPath: "db.sqlite")
    }
}
try prepareDirectory()

// snippet.show
let database = try Database.open(
    at: "db.sqlite",
    options: [.create, .readwrite]
)

let createTable = """
    CREATE TABLE IF NOT EXISTS contacts(
        id INT PRIMARY KEY NOT NULL,
        name TEXT
    );
    """
try database.execute(createTable)

let insert = try database.prepare("INSERT INTO contacts (id, name) VALUES (?, ?);")
//try insert.bind(parameters: 1, "Paul").execute()
//try insert.bind(parameters: 2, "John").execute()

// snippet.sql
let insertSQL = insert.sql  // "INSERT INTO contacts (id, name) VALUES (?, ?);"

// snippet.hide
print("           SQL:", insertSQL)
print("  Expanded SQL:", insert.expandedSQL)
print("Normalized SQL:", insert.normalizedSQL)

precondition(insertSQL == "INSERT INTO contacts (id, name) VALUES (?, ?);")
