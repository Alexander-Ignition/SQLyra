import Foundation
import SQLyra
import Testing

struct Contact: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let rating: Double?
    let image: Data?
}

private let createTableContacts =
    """
    CREATE TABLE contacts (
        id INT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        rating FLOAT,
        image BLOB
    );
    """

struct PreparedStatementTests {
    private let db: Database

    init() throws {
        db = try Database.open(at: ":memory:", options: [.readwrite, .memory, .extendedResultCode])
        try db.execute(createTableContacts)
    }

    @Test func sql() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (:id, :name)")
        #expect(insert.sql == "INSERT INTO contacts (id, name) VALUES (:id, :name)")
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            #expect(insert.normalizedSQL == "INSERT INTO contacts(id,name)VALUES(?,?);")
        }
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, NULL)")

        try insert.bind(name: ":name", "John")
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, 'John')")
    }

    @Test func parameters() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (?, :name)")
        #expect(insert.parameterCount == 2)
        #expect(insert.parameterName(at: 1) == nil)
        #expect(insert.parameterName(at: 2) == ":name")
        #expect(insert.parameterIndex(for: ":name") == 2)
    }

    @Test func clear() throws {
        let insert = try db.prepare("INSERT INTO contacts (id, name) VALUES (:id, :name)")

        try insert.bind(name: ":id", 2).bind(name: ":name", "Bob").execute()
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (2, 'Bob')")

        try insert.clear()
        #expect(insert.expandedSQL == "INSERT INTO contacts (id, name) VALUES (NULL, NULL)")
    }

    @Test func bind() throws {
        let insertContract = "INSERT INTO contacts (id, name, rating, image)"
        let insert = try db.prepare("\(insertContract) VALUES (:id, :name, :rating, :image)")

        try insert
            .bind(name: ":id", 10)
            .bind(name: ":name", "A")
            .bind(name: ":rating", 1.0)
            .bind(name: ":image", .blob(Data("123".utf8)))
        #expect(insert.expandedSQL == "\(insertContract) VALUES (10, 'A', 1.0, x'313233')")

        try insert
            .bind(index: 1, 20)
            .bind(index: 2, "B")
            .bind(index: 3, 0.0)
            .bind(index: 4, nil)
        #expect(insert.expandedSQL == "\(insertContract) VALUES (20, 'B', 0.0, NULL)")
    }

    @Test func columns() throws {
        let sgl = "INSERT INTO contacts (id, name, rating, image) VALUES (:id, :name, :rating, :image);"
        let insert = try db.prepare(sgl)

        try insert
            .bind(name: ":id", 5)
            .bind(name: ":name", "A")
            .bind(name: ":rating", 2.0)
            .execute()
            .reset()
            .clear()

        try insert
            .bind(name: ":id", 6)
            .bind(name: ":name", "B")
            .bind(name: ":image", .blob(Data("123".utf8)))
            .execute()

        let select = try db.prepare("SELECT * FROM contacts;")
        #expect(select.columnCount == 4)

        var contracts: [Contact] = []
        while try select.step() {
            let contact = Contact(
                id: Int(select.columnInt64(at: 0)),
                name: select.columnString(at: 1) ?? "",
                rating: select.columnDouble(at: 2),
                image: select.columnBlob(at: 3)
            )
            contracts.append(contact)
        }
        let expected = [
            Contact(id: 5, name: "A", rating: 2.0, image: nil),
            Contact(id: 6, name: "B", rating: 0, image: Data("123".utf8)),
        ]
        #expect(contracts == expected)
    }
}
