import Foundation
import SQLyra
import Testing

struct Contact: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let rating: Double?
    let image: Data?

    static let table = "CREATE TABLE contacts (id INT, name TEXT, rating FLOAT, image BLOB);"
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

        try insert.bind(parameters: 5, "A", 2.0, .null).execute().reset()
        try insert.bind(parameters: 6, "B", .null, .blob(Data("123".utf8))).execute()

        let select = try db.prepare("SELECT * FROM contacts;")
        #expect(select.columnCount == 4)

        var contracts: [Contact] = []
        while try select.step() {
            let contact = Contact(
                id: Int(select.column(at: 0).int64),
                name: select.column(at: 1).string ?? "",
                rating: select.column(at: 2).double,
                image: select.column(at: 3).blob
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
