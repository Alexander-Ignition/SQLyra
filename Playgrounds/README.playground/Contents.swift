/*:
 # 🌌 SQLyra 🎼

 [![Test](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml/badge.svg)](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml)
 [![Swift 5.9](https://img.shields.io/badge/swift-5.9-brightgreen.svg?style=flat)](https://developer.apple.com/swift)
 [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Alexander-Ignition/SQLyra/blob/master/LICENSE)

 Swift SQLite wrapper.

 [Documentation](https://alexander-ignition.github.io/SQLyra/documentation/sqlyra/)

 > this readme file is available as Xcode playground in Playgrounds/README.playground

 ## Open

 Create database in memory for reading and writing.
 */
import SQLyra

let database = try Database.open(
    at: "new.db",
    options: [.readwrite, .memory]
)
/*:
 ## Create table

 Create table for contacts with fields `id` and `name`.
 */
let sql = """
    CREATE TABLE contacts(
        id INT PRIMARY KEY NOT NULL,
        name TEXT
    );
    """
try database.execute(sql)
/*:
 ## Insert

 Insert new contacts Paul and John.
 */
let insert = try database.prepare("INSERT INTO contacts (id, name) VALUES (?, ?);")
try insert.bind(parameters: 1, "Paul").execute().reset()
try insert.bind(parameters: 2, "John").execute()
/*:
 ## Select

 Select all contacts from database.
 */
struct Contact: Codable {
    let id: Int
    let name: String
}

let select = try database.prepare("SELECT * FROM contacts;")
let contacts = try select.array(Contact.self)
