import Foundation
import SQLyra
import Testing

struct Contact: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let rating: Double?
    let image: Data?

    static let table = "CREATE TABLE contacts (id INT, name TEXT, rating REAL, image BLOB) STRICT;"
    static let insert = "INSERT INTO contacts (id, name, rating, image) VALUES (:id, :name, :rating, :image)"
}

struct PreparedStatementTests {
    private let db: Database

    init() throws {
        db = try Database.open(at: ":memory:", options: [.readwrite, .memory])
        try db.execute(Contact.table)
    }

    @Test func sql() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (:id, :name)")
        #expect(insert.sql == "INSERT INTO contacts (id, name) VALUES (:id, :name)")
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            #expect(insert.normalizedSQL == "INSERT INTO contacts(id,name)VALUES(?,?);")
        }
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, NULL)")

        try insert.bind(name: ":name", parameter: "John")
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, 'John')")
    }

    @Test func parameters() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (?, :name)")
        #expect(insert.parameterCount == 2)
        #expect(insert.parameterName(at: 1) == nil)
        #expect(insert.parameterName(at: 2) == ":name")
        #expect(insert.parameterIndex(for: ":name") == 2)
    }

    @Test func clearBindings() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (:id, :name)")

        try insert.bind(parameters: 2, "Bob").execute()
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (2, 'Bob')")

        try insert.clearBindings()
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, NULL)")
    }

    @Test func bind() throws {
        let insert = try db.prepare(Contact.insert)

        try insert
            .bind(name: ":id", parameter: 10)
            .bind(name: ":name", parameter: "A")
            .bind(name: ":rating", parameter: 1.0)
            .bind(name: ":image", parameter: .blob(Data("123".utf8)))
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name, rating, image) VALUES (10, 'A', 1.0, x'313233')")

        try insert
            .bind(index: 1, parameter: 20)
            .bind(index: 2, parameter: "B")
            .bind(index: 3, parameter: 0.0)
            .bind(index: 4, parameter: nil)
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name, rating, image) VALUES (20, 'B', 0.0, NULL)")
    }

    @Test func columns() throws {
        let insert = try db.prepare(Contact.insert)

        try insert.bind(parameters: 5, "A", 2.0, .null).execute()
        try insert.bind(parameters: 6, "B", .null, .blob(Data("123".utf8))).execute()

        let select = try db.prepare("SELECT * FROM contacts;")
        #expect(select.columnCount == 4)

        var contracts: [Contact] = []
        while let row = try select.row() {
            let contact = Contact(
                id: row.id?.int ?? 0,
                name: row.name?.string ?? "",
                rating: row.rating?.double ?? 0,
                image: row.image?.blob
            )
            contracts.append(contact)
        }
        let expected = [
            Contact(id: 5, name: "A", rating: 2.0, image: nil),
            Contact(id: 6, name: "B", rating: 0, image: Data("123".utf8)),
        ]
        #expect(contracts == expected)
    }

    @Test func decode() throws {
        let insert = try db.prepare(Contact.insert)

        try insert.bind(parameters: 5, "A", 2.0, .null).execute()
        try insert.bind(parameters: 6, "B", .null, .blob(Data("123".utf8))).execute()

        let select = try db.prepare("SELECT * FROM contacts;")
        let contracts = try select.array(Contact.self)

        let expected = [
            Contact(id: 5, name: "A", rating: 2.0, image: nil),
            Contact(id: 6, name: "B", rating: nil, image: Data("123".utf8)),
        ]
        #expect(contracts == expected)
    }

    @Test func execute() throws {
        let insert = try db.prepare(Contact.insert)

        try insert.bind(name: ":id", parameter: "invalid")
        #expect(throws: DatabaseError.self) { try insert.execute() }

        try insert.bind(name: ":id", parameter: 4)
        #expect(throws: Never.self) { try insert.execute() }
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    @Test func dataFrame() throws {
        let insert = try db.prepare(Contact.insert)

        try insert.bind(parameters: 5, "A").execute()
        try insert.bind(parameters: 6, "B").execute()

        let df = try db.prepare("SELECT * FROM contacts;").dataFrame()
        let expected = """
            ┏━━━┳━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━┓
            ┃   ┃ id    ┃ name     ┃ rating   ┃ image  ┃
            ┃   ┃ <Int> ┃ <String> ┃ <Double> ┃ <Data> ┃
            ┡━━━╇━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━┩
            │ 0 │     5 │ A        │      nil │ nil    │
            │ 1 │     6 │ B        │      nil │ nil    │
            └───┴───────┴──────────┴──────────┴────────┘
            2 rows, 4 columns
            """
        #expect(df.description == expected + "\n")
    }

    @Test static func retainDatabase() throws {
        weak var db: Database?
        var statement: PreparedStatement?
        do {
            let suite = try PreparedStatementTests()
            db = suite.db
            statement = try suite.db.prepare("SELECT * FROM contacts;")
        }
        try #require(statement != nil)
        #expect(db != nil)
        statement = nil
        #expect(db == nil)
    }
}
