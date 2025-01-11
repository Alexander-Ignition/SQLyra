import Foundation
import SQLyra
import Testing

struct RowDecoderTests {
    struct SignedIntegers {
        /// valid parameters for all signed integers
        static let arguments: [(SQLParameter, Int)] = [
            (-1, -1),
            (0, 0),
            (1, 1),
            (0.9, 0),
            ("2", 2),
            (.blob(Data("3".utf8)), 3),
        ]

        struct IntTests: DecodableValueSuite {
            let value: Int

            @Test(arguments: SignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Int) throws {
                try _decode(parameter, Int(expected))
            }
        }

        struct Int8Tests: DecodableValueSuite {
            let value: Int8

            @Test(arguments: SignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Int) throws {
                try _decode(parameter, Int8(expected))
            }
        }

        struct Int16Tests: DecodableValueSuite {
            let value: Int16

            @Test(arguments: SignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Int) throws {
                try _decode(parameter, Int16(expected))
            }
        }

        struct Int32Tests: DecodableValueSuite {
            let value: Int32

            @Test(arguments: SignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Int) throws {
                try _decode(parameter, Int32(expected))
            }
        }

        struct Int64Tests: DecodableValueSuite {
            let value: Int64

            @Test(arguments: SignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Int) throws {
                try _decode(parameter, Int64(expected))
            }
        }
    }

    struct UnsignedIntegers {
        /// valid parameters for all unsigned integers
        static let arguments: [(SQLParameter, UInt)] = [
            (0, 0),
            (1, 1),
            (0.9, 0),
            ("2", 2),
            (.blob(Data("3".utf8)), 3),
        ]

        struct UIntTests: DecodableValueSuite {
            let value: UInt

            @Test(arguments: UnsignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: UInt) throws {
                try _decode(parameter, UInt(expected))
            }
        }

        struct UInt8Tests: DecodableValueSuite {
            let value: UInt8

            @Test(arguments: UnsignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: UInt) throws {
                try _decode(parameter, UInt8(expected))
            }

            @Test(arguments: [
                SQLParameter.int64(-1),
                SQLParameter.int64(Int64.max),
            ])
            static func dataCorrupted(_ parameter: SQLParameter) throws {
                try _dataCorrupted(parameter, "Parsed SQL int64 <\(parameter)> does not fit in UInt8.")
            }
        }

        struct UInt16Tests: DecodableValueSuite {
            let value: UInt16

            @Test(arguments: UnsignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: UInt) throws {
                try _decode(parameter, UInt16(expected))
            }
        }

        struct UInt32Tests: DecodableValueSuite {
            let value: UInt32

            @Test(arguments: UnsignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: UInt) throws {
                try _decode(parameter, UInt32(expected))
            }
        }

        struct UInt64Tests: DecodableValueSuite {
            let value: UInt64

            @Test(arguments: UnsignedIntegers.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: UInt) throws {
                try _decode(parameter, UInt64(expected))
            }
        }
    }

    struct FloatingPointNumerics {
        static let arguments: [(SQLParameter, Double)] = [
            (-1, -1.0),
            (0, 0.0),
            (1, 1.0),
            (0.5, 0.5),
            ("0.5", 0.5),
            ("1.0", 1.0),
            (.blob(Data("1".utf8)), 1.0),
        ]

        struct DoubleTests: DecodableValueSuite {
            let value: Double

            @Test(arguments: FloatingPointNumerics.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Double) throws {
                try _decode(parameter, Double(expected))
            }
        }

        struct FloatTests: DecodableValueSuite {
            let value: Float

            @Test(arguments: FloatingPointNumerics.arguments)
            static func decode(_ parameter: SQLParameter, _ expected: Double) throws {
                try _decode(parameter, Float(expected))
            }

            @Test static func dataCorrupted() throws {
                let parameter = SQLParameter.double(Double.greatestFiniteMagnitude)
                try _dataCorrupted(parameter, "Parsed SQL double <\(parameter)> does not fit in Float.")
            }
        }
    }

    struct BoolTests: DecodableValueSuite {
        let value: Bool

        @Test(arguments: [
            (SQLParameter.int64(0), false),
            (SQLParameter.int64(1), true),
            (SQLParameter.double(0.9), false),
            (SQLParameter.text("abc"), false),
            (SQLParameter.text("true"), false),
            (SQLParameter.blob(Data("zxc".utf8)), false),
            (SQLParameter.blob(Data("1".utf8)), true),
        ])
        static func decode(_ parameter: SQLParameter, _ expected: Bool) throws {
            try _decode(parameter, expected)
        }
    }

    struct StringTests: DecodableValueSuite {
        let value: String

        @Test(arguments: [
            (SQLParameter.int64(0), "0"),
            (SQLParameter.int64(1), "1"),
            (SQLParameter.double(0.9), "0.9"),
            (SQLParameter.text("abc"), "abc"),
            (SQLParameter.blob(Data("zxc".utf8)), "zxc"),
        ])
        static func decode(_ parameter: SQLParameter, _ expected: String) throws {
            try _decode(parameter, expected)
        }
    }

    struct DataTests: DecodableValueSuite {
        let value: Data

        @Test(arguments: [
            (SQLParameter.int64(1), Data("1".utf8)),
            (SQLParameter.double(1.1), Data("1.1".utf8)),
            (SQLParameter.text("123"), Data("123".utf8)),
            (SQLParameter.blob(Data("zxc".utf8)), Data("zxc".utf8)),
        ])
        static func decode(_ parameter: SQLParameter, _ expected: Data) throws {
            try _decode(parameter, expected)
        }
    }

    struct OptionalTests: DecodableValueSuite {
        let value: Int?

        @Test static func decode() throws {
            try _decode(1, 1)
        }
    }

    struct DecodingErrorTests: Decodable {
        let item: Int  // invalid

        @Test static func keyNotFound() throws {
            let repo = try ItemRepository(datatype: "ANY")
            let row = try #require(try repo.select(.int64(1)).row())
            #expect {
                try row.decode(DecodingErrorTests.self)
            } throws: { error in
                guard case .keyNotFound(let key, let context) = error as? DecodingError else {
                    return false
                }
                return key.stringValue == "item"
                    && context.codingPath.map(\.stringValue) == ["item"]
                    && context.debugDescription == "Column index not found for key: \(key)"
                    && context.underlyingError == nil
            }
        }

        @Test static func typeMismatch() throws {
            let errorMatcher = { (error: any Error) -> Bool in
                guard case .typeMismatch(_, let context) = error as? DecodingError else {
                    return false
                }
                return context.codingPath.isEmpty && context.debugDescription == "" && context.underlyingError == nil
            }
            let repo = try ItemRepository(datatype: "ANY")
            let row = try #require(try repo.select(.int64(1)).row())
            #expect(performing: { try row.decode(Int.self) }, throws: errorMatcher)
            #expect(performing: { try row.decode([Int].self) }, throws: errorMatcher)
        }

        @Test static func valueNotFound() throws {
            let repo = try ItemRepository(datatype: "ANY")
            let row = try #require(try repo.select(.null).row())
            #expect {
                try row.decode(Single<Int8>.self)
            } throws: { error in
                guard case .valueNotFound(let type, let context) = error as? DecodingError else {
                    return false
                }
                return type == Int8.self
                    && context.codingPath.map(\.stringValue) == ["value"]
                    && context.debugDescription == "Column value not found for key: \(context.codingPath[0])"
                    && context.underlyingError == nil
            }
        }
    }
}

// MARK: - Test Suite

protocol DecodableValueSuite: Decodable {
    associatedtype Value: Decodable, Equatable

    var value: Value { get }
}

extension DecodableValueSuite {
    static func _decode(
        _ parameter: SQLParameter,
        _ expected: Value,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let repo = try ItemRepository(datatype: "ANY")
        let select = try repo.select(parameter)
        let row = try #require(try select.row(), sourceLocation: sourceLocation)

        let keyed = try row.decode(Self.self)
        #expect(keyed.value == expected, sourceLocation: sourceLocation)

        let single = try row.decode(Single<Value>.self)
        #expect(single.value == expected, sourceLocation: sourceLocation)

        #expect(try select.row() == nil, sourceLocation: sourceLocation)
    }

    static func _dataCorrupted(
        _ parameter: SQLParameter,
        _ message: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let repo = try ItemRepository(datatype: "ANY")
        let row = try #require(try repo.select(parameter).row(), sourceLocation: sourceLocation)
        #expect(sourceLocation: sourceLocation) {
            try row.decode(Self.self)
        } throws: { error in
            guard case .dataCorrupted(let context) = error as? DecodingError else {
                return false
            }
            return context.codingPath.map(\.stringValue) == ["value"]
                && context.debugDescription == message
                && context.underlyingError == nil
        }
    }
}

struct Single<T: Decodable>: Decodable {
    let value: T
}

struct ItemRepository {
    private let db: Database

    init(datatype: String) throws {
        db = try Database.open(at: ":memory:", options: [.readwrite, .memory])
        try db.execute("CREATE TABLE items (value \(datatype));")
    }

    func select(_ parameter: SQLParameter) throws -> PreparedStatement {
        try db.prepare("INSERT INTO items (value) VALUES (?);").bind(index: 1, parameter: parameter).execute()
        return try db.prepare("SELECT value FROM items;")
    }
}
