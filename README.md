# 🌌 SQLyra 🎼

[![Test](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml/badge.svg)](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-brightgreen.svg?style=flat)](https://developer.apple.com/swift)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Alexander-Ignition/SQLyra/blob/master/LICENSE)

Swift SQLite wrapper.

[Documentation](https://alexander-ignition.github.io/SQLyra/documentation/sqlyra/)

> this readme file is available as Xcode playground in Playgrounds/README.playground

## Open

Create database in memory for reading and writing.
```swift
import SQLyra

let database = try Database.open(
    at: "new.db",
    options: [.readwrite, .memory]
)
```
## Create table

Create table for contacts with fields `id` and `name`.
```swift
let sql = """
    CREATE TABLE contacts(
        id INT PRIMARY KEY NOT NULL,
        name TEXT
    );
    """
try database.execute(sql)
```
## Insert

Insert new contacts Paul and John.
```swift
let insert = try database.prepare("INSERT INTO contacts (id, name) VALUES (?, ?);")
try insert.bind(parameters: 1, "Paul").execute().reset()
try insert.bind(parameters: 2, "John").execute()
```
## Select

Select all contacts from database.
```swift
struct Contact: Codable {
    let id: Int
    let name: String
}

let select = try database.prepare("SELECT * FROM contacts;")
let contacts = try select.array(Contact.self)
```
## DataFrame

The [DataFrame](https://developer.apple.com/documentation/tabulardata/dataframe) from the [TabularData](https://developer.apple.com/documentation/tabulardata) framework is supported.

It can help to print the table.
```swift
let df = try database.prepare("SELECT * FROM contacts;").dataFrame()
print(df)
```
```
┏━━━┳━━━━━━━┳━━━━━━━━━━┓
┃   ┃ id    ┃ name     ┃
┃   ┃ <Int> ┃ <String> ┃
┡━━━╇━━━━━━━╇━━━━━━━━━━┩
│ 0 │     1 │ Paul     │
│ 1 │     2 │ John     │
└───┴───────┴──────────┘
```
## License

MIT
