// snippet.hide
import SQLyra

let database = try Database.open(at: ":memory:", options: [.readwrite, .memory])
try database.execute("CREATE TABLE employees (id INT PRIMARY KEY NOT NULL, name TEXT);")

// snippet.show
database.setExtendedResultCodesEnabled(true)  // or `Database.OpenOptions.extendedResultCode`

let errorCode = 19  // SQLITE_CONSTRAINT
let extendedErrorCode = 1299  // SQLITE_CONSTRAINT_NOTNULL

do {
    try database.execute("INSERT INTO employees (name) VALUES ('John');")
} catch let error {
    assert(error.code != errorCode)
    assert(error.code == extendedErrorCode)
    assert(error.codeDescription == "constraint failed")
    assert(error.message == "NOT NULL constraint failed: employees.id")
}
assert(database.errorCode != errorCode)
assert(database.errorCode == extendedErrorCode)
assert(database.extendedErrorCode == extendedErrorCode)
assert(database.errorMessage == "NOT NULL constraint failed: employees.id")
