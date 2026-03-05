#if !os(Linux)

// snippet.hide
import SQLyra

let db = try Database.open(at: ":memory:", options: [.memory, .readwrite])
try db.execute("CREATE TABLE IF NOT EXISTS contacts (id INT, name TEXT);")

// snippet.show
let statement = try db.prepare("INSERT INTO contacts (id, name) VALUES (?, ?);")
try statement.bind(parameters: 1, "Paul")

let sql1 = statement.sql  // INSERT INTO contacts (id, name) VALUES (?, ?);
let sql2 = statement.expandedSQL  // INSERT INTO contacts (id, name) VALUES (1, 'Paul');
let sql3 = statement.normalizedSQL  // INSERT INTO contacts(id,name)VALUES(?,?);

// snippet.hide
precondition(sql1 == "INSERT INTO contacts (id, name) VALUES (?, ?);")
precondition(sql2 == "INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
precondition(sql3 == "INSERT INTO contacts(id,name)VALUES(?,?);")

#endif
