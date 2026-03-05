// snippet.hide
import SQLyra

let db = try Database.open(at: ":memory:", options: [.memory, .readwrite])
try db.execute("CREATE TABLE users (id INT, email TEXT);")

// snippet.show
let statement = try db.prepare("INSERT INTO users (id, email) VALUES (?, :login)")

let count = statement.parameterCount  // 2
let name1 = statement.parameterName(at: 1)  // nil
let name2 = statement.parameterName(at: 2)  // :name
let index1 = statement.parameterIndex(for: ":id")  // 0
let index2 = statement.parameterIndex(for: ":login")  // 2

// snippet.hide
precondition(count == 2)
precondition(name1 == nil)
precondition(name2 == ":login")
precondition(index1 == 0)
precondition(index2 == 2)
