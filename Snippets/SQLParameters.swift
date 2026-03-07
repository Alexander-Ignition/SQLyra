// snippet.hide
import SQLyra

let db = try Database.open(at: ":memory:", options: [.memory, .readwrite])
try db.execute("CREATE TABLE users (id INT, email TEXT);")

// snippet.show
let statement = try db.prepare("INSERT INTO users (id, email) VALUES (?, :login)")

assert(statement.parameterCount == 2)
assert(statement.parameterName(at: 1) == nil)
assert(statement.parameterName(at: 2) == ":login")
assert(statement.parameterIndex(for: ":id") == 0)  // invalid
assert(statement.parameterIndex(for: ":login") == 2)
