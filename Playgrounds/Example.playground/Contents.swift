/*:
 # 🍋 SQLime
 */
import Foundation
import SQLyra  // open Package.swift and select Playgrounds/Example

/*:
 ## Open

 Create database in memory for reading and writing.
 */
let database = try Database.open(
    at: "new.db",
    options: [.readwrite, .memory]
)
/*:
 ## Create table

 Create table for contacts with fileds `id` and `name`.
 */
try database.execute(
    """
    CREATE TABLE contacts(
        id INT PRIMARY KEY NOT NULL,
        name CHAR(255)
    );
    """
)
/*:
 ## Insert

 Insert new contacts Paul and John.
 */
try database.execute("INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
try database.execute("INSERT INTO contacts (id, name) VALUES (2, 'John');")
/*:
 ## Select

 Select all contacts from database.
 */
var rows: [[String: String]] = []
try database.execute("SELECT * FROM contacts;") { rows.append($0) }
rows
