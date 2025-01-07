# 🌌 SQLyra 🎼

[![Test](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml/badge.svg)](https://github.com/Alexander-Ignition/SQLyra/actions/workflows/test.yml)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-brightgreen.svg?style=flat)](https://developer.apple.com/swift)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Alexander-Ignition/SQLyra/blob/master/LICENSE)

Swift SQLite wrapper.

[Documentation](https://alexander-ignition.github.io/SQLyra/documentation/sqlyra/)

- Note: this readme file is available as Xcode playground in Playgrounds/README.playground

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
try database.execute(
    """
    CREATE TABLE contacts(
        id INT PRIMARY KEY NOT NULL,
        name TEXT
    );
    """
)
```
## Insert

Insert new contacts Paul and John.
```swift
try database.execute("INSERT INTO contacts (id, name) VALUES (1, 'Paul');")
try database.execute("INSERT INTO contacts (id, name) VALUES (2, 'John');")
```
## Select

Select all contacts from database.
```swift
struct Contact: Codable {
    let id: Int
    let name: String
}

let contacts = try database.prepare("SELECT * FROM contacts;").array(Contact.self)
```
