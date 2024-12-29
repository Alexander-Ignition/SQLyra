import Foundation
import SQLite3

/// An object that decodes instances of a data type from ``PreparedStatement``.
public struct StatementDecoder {
    /// A dictionary you use to customize the decoding process by providing contextual information.
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Creates a new, reusable Statement decoder.
    public init() {}

    public func decode<T>(_ type: T.Type, from statement: PreparedStatement) throws -> T where T: Decodable {
        let decoder = _StatementDecoder(
            statement: statement,
            userInfo: userInfo
        )
        return try type.init(from: decoder)
    }
}

private final class _StatementDecoder {
    let statement: PreparedStatement
    let columns: [String: Int32]
    let userInfo: [CodingUserInfoKey: Any]
    private(set) var codingPath: [any CodingKey] = []

    init(statement: PreparedStatement, userInfo: [CodingUserInfoKey: Any]) {
        self.statement = statement
        self.userInfo = userInfo
        self.columns = statement.columnIndexByName
        self.codingPath.reserveCapacity(3)
    }

    @inline(__always)
    func null<K>(for key: K) -> Bool where K: CodingKey {
        columns[key.stringValue].map { statement.columnNull(at: $0) } ?? true
    }

    @inline(__always)
    func bool<K>(forKey key: K) throws -> Bool where K: CodingKey {
        try integer(Int64.self, forKey: key) != 0
    }

    @inline(__always)
    func string<K>(forKey key: K, single: Bool = false) throws -> String where K: CodingKey {
        let index = try columnIndex(forKey: key, single: single)
        guard let value = statement.columnString(at: index) else {
            throw DecodingError.valueNotFound(String.self, context(key, single, ""))
        }
        return value
    }

    @inline(__always)
    func floating<T, K>(_ type: T.Type, forKey key: K, single: Bool = false) throws -> T
    where T: BinaryFloatingPoint, K: CodingKey {
        let index = try columnIndex(forKey: key, single: single)
        let value = statement.columnDouble(at: index)
        guard let number = type.init(exactly: value) else {
            throw DecodingError.dataCorrupted(context(key, single, numberNotFit(type, value: "\(value)")))
        }
        return number
    }

    @inline(__always)
    func integer<T, K>(_ type: T.Type, forKey key: K, single: Bool = false) throws -> T where T: Numeric, K: CodingKey {
        let index = try columnIndex(forKey: key, single: single)
        let value = statement.columnInt64(at: index)
        guard let number = type.init(exactly: value) else {
            throw DecodingError.dataCorrupted(context(key, single, numberNotFit(type, value: "\(value)")))
        }
        return number
    }

    @inline(__always)
    func decode<T, K>(
        _ type: T.Type,
        forKey key: K,
        single: Bool = false
    ) throws -> T where T: Decodable, K: CodingKey {
        if type == Data.self {
            let index = try columnIndex(forKey: key, single: single)
            guard let data = statement.columnBlob(at: index) else {
                throw DecodingError.valueNotFound(Data.self, context(key, single, ""))
            }
            // swift-format-ignore: NeverForceUnwrap
            return data as! T
        }
        if single {
            return try type.init(from: self)
        }
        codingPath.append(key)
        defer {
            codingPath.removeLast()
        }
        return try type.init(from: self)
    }

    private func columnIndex<K>(forKey key: K, single: Bool) throws -> Int32 where K: CodingKey {
        guard let index = columns[key.stringValue] else {
            throw DecodingError.keyNotFound(key, context(key, single, "Column index not found for key: \(key)"))
        }
        return index
    }

    private func context(_ key: any CodingKey, _ single: Bool, _ message: String) -> DecodingError.Context {
        var path = codingPath
        if !single {
            path.append(key)
        }
        return DecodingError.Context(codingPath: path, debugDescription: message)
    }
}

private func numberNotFit(_ type: any Any.Type, value: String) -> String {
    "Parsed SQL number <\(value)> does not fit in \(type)."
}

// MARK: - Decoder

extension _StatementDecoder: Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "`unkeyedContainer()` not supported"
        )
        throw DecodingError.dataCorrupted(context)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        if codingPath.isEmpty {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "key not found")
            throw DecodingError.dataCorrupted(context)
        }
        return self
    }
}

// MARK: - SingleValueDecodingContainer

extension _StatementDecoder: SingleValueDecodingContainer {
    // swift-format-ignore: NeverForceUnwrap
    private var key: any CodingKey { codingPath.last! }

    func decodeNil() -> Bool { null(for: key) }
    func decode(_ type: Bool.Type) throws -> Bool { try bool(forKey: key) }
    func decode(_ type: String.Type) throws -> String { try string(forKey: key, single: true) }
    func decode(_ type: Double.Type) throws -> Double { try floating(type, forKey: key, single: true) }
    func decode(_ type: Float.Type) throws -> Float { try floating(type, forKey: key, single: true) }
    func decode(_ type: Int.Type) throws -> Int { try integer(type, forKey: key, single: true) }
    func decode(_ type: Int8.Type) throws -> Int8 { try integer(type, forKey: key, single: true) }
    func decode(_ type: Int16.Type) throws -> Int16 { try integer(type, forKey: key, single: true) }
    func decode(_ type: Int32.Type) throws -> Int32 { try integer(type, forKey: key, single: true) }
    func decode(_ type: Int64.Type) throws -> Int64 { try integer(type, forKey: key, single: true) }
    func decode(_ type: UInt.Type) throws -> UInt { try integer(type, forKey: key, single: true) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try integer(type, forKey: key, single: true) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try integer(type, forKey: key, single: true) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try integer(type, forKey: key, single: true) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try integer(type, forKey: key, single: true) }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable { try decode(type, forKey: key, single: true) }
}

// MARK: - KeyedDecodingContainer

extension _StatementDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let decoder: _StatementDecoder
        var codingPath: [any CodingKey] { decoder.codingPath }
        var allKeys: [Key] { decoder.columns.keys.compactMap { Key(stringValue: $0) } }

        func contains(_ key: Key) -> Bool { decoder.columns.keys.contains(key.stringValue) }
        func decodeNil(forKey key: Key) throws -> Bool { decoder.null(for: key) }
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try decoder.bool(forKey: key) }
        func decode(_ type: String.Type, forKey key: Key) throws -> String { try decoder.string(forKey: key) }
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try decoder.floating(type, forKey: key) }
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try decoder.floating(type, forKey: key) }
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try decoder.integer(type, forKey: key) }
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try decoder.integer(type, forKey: key) }
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try decoder.integer(type, forKey: key) }
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try decoder.integer(type, forKey: key) }
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try decoder.integer(type, forKey: key) }
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try decoder.integer(type, forKey: key) }
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try decoder.integer(type, forKey: key) }
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try decoder.integer(type, forKey: key) }
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try decoder.integer(type, forKey: key) }
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try decoder.integer(type, forKey: key) }
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            try decoder.decode(type, forKey: key)
        }

        func superDecoder() throws -> any Decoder { fatalError() }
        func superDecoder(forKey key: Key) throws -> any Decoder { fatalError() }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { fatalError() }
        func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            fatalError()
        }
    }
}
