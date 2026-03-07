// snippet.hide
#if !os(Linux)

import SQLyra

let db = try Database.open(at: ":memory:", options: [.memory, .readwrite])
try db.execute("CREATE TABLE IF NOT EXISTS contacts (id INT, name TEXT);")

// snippet.show
let statement = try db.prepare("INSERT INTO contacts (id, name) VALUES (?, ?);")
try statement.bind(parameters: 1, "Paul")

assert(statement.sql == "INSERT INTO contacts (id, name) VALUES (?, ?);")
assert(statement.expandedSQL == "INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
assert(statement.normalizedSQL == "INSERT INTO contacts(id,name)VALUES(?,?);")

// snippet.hide
#endif
