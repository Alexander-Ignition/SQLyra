import Foundation
import SQLite3

/// An object that decodes instances of a data type from ``PreparedStatement``.
public final class RowDecoder {
    nonisolated(unsafe) static let `default` = RowDecoder()

    /// A dictionary you use to customize the decoding process by providing contextual information.
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Creates a new, reusable row decoder.
    public init() {}

    public func decode<T>(_ type: T.Type, from row: PreparedStatement.Row) throws -> T where T: Decodable {
        let decoder = _RowDecoder(row: row, userInfo: userInfo)
        return try type.init(from: decoder)
    }
}

private struct _RowDecoder: Decoder {
    let row: PreparedStatement.Row

    // MARK: - Decoder

    let userInfo: [CodingUserInfoKey: Any]
    var codingPath: [any CodingKey] { [] }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        throw DecodingError.typeMismatch(PreparedStatement.self, context)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        throw DecodingError.typeMismatch(PreparedStatement.self, context)
    }

    // MARK: - KeyedDecodingContainer

    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let decoder: _RowDecoder
        var codingPath: [any CodingKey] { decoder.codingPath }
        var allKeys: [Key] { decoder.row.statement.columnIndexByName.keys.compactMap { Key(stringValue: $0) } }

        func contains(_ key: Key) -> Bool { decoder.row.statement.columnIndexByName.keys.contains(key.stringValue) }
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
            return try decoder.decode(type, forKey: key)
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

    // MARK: - Decoding Values

    @inline(__always)
    func null<K>(for key: K) -> Bool where K: CodingKey {
        row[key.stringValue]?.isNull ?? true
    }

    @inline(__always)
    func bool<K>(forKey key: K) throws -> Bool where K: CodingKey {
        try integer(Int64.self, forKey: key) != 0
    }

    @inline(__always)
    func integer<T, K>(_ type: T.Type, forKey key: K) throws -> T where T: Numeric, K: CodingKey {
        let value = try column(forKey: key)
        guard let number = type.init(exactly: value.int64) else {
            let message = "Parsed SQL integer <\(value)> does not fit in \(type)."
            let context = DecodingError.Context(codingPath: [key], debugDescription: message)
            throw DecodingError.dataCorrupted(context)
        }
        return number
    }

    @inline(__always)
    func floating<T, K>(_ type: T.Type, forKey key: K) throws -> T where T: BinaryFloatingPoint, K: CodingKey {
        let value = try column(forKey: key)
        guard let number = type.init(exactly: value.double) else {
            let message = "Parsed SQL double <\(value)> does not fit in \(type)."
            let context = DecodingError.Context(codingPath: [key], debugDescription: message)
            throw DecodingError.dataCorrupted(context)
        }
        return number
    }

    @inline(__always)
    func string<K>(forKey key: K) throws -> String where K: CodingKey {
        let value = try column(forKey: key)
        guard let value = value.string else {
            throw DecodingError.valueNotFound(String.self, .codingPath([key]))
        }
        return value
    }

    @inline(__always)
    func decode<T, K>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable, K: CodingKey {
        if type == Data.self {
            let value = try column(forKey: key)
            guard let data = value.blob else {
                throw DecodingError.valueNotFound(Data.self, .codingPath([key]))
            }
            // swift-format-ignore: NeverForceUnwrap
            return data as! T
        }
        let decoder = _ColumnDecoder(key: key, decoder: self)
        return try type.init(from: decoder)
    }

    @inline(__always)
    private func column<K>(forKey key: K) throws -> PreparedStatement.Column where K: CodingKey {
        guard let index = row.statement.columnIndexByName[key.stringValue] else {
            let message = "Column index not found for key: \(key)"
            let context = DecodingError.Context(codingPath: [key], debugDescription: message)
            throw DecodingError.keyNotFound(key, context)
        }
        return row[index]
    }
}

private extension DecodingError.Context {
    static func codingPath(_ path: [any CodingKey]) -> DecodingError.Context {
        DecodingError.Context(codingPath: path, debugDescription: "")
    }
}

private struct _ColumnDecoder: Decoder, SingleValueDecodingContainer {
    let key: any CodingKey
    let decoder: _RowDecoder

    // MARK: - Decoder

    var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo }
    var codingPath: [any CodingKey] { [key] }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        throw DecodingError.typeMismatch(PreparedStatement.Column.self, context)
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        throw DecodingError.typeMismatch(PreparedStatement.Column.self, context)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        self
    }

    // MARK: - SingleValueDecodingContainer

    func decodeNil() -> Bool { decoder.null(for: key) }
    func decode(_ type: Bool.Type) throws -> Bool { try decoder.bool(forKey: key) }
    func decode(_ type: String.Type) throws -> String { try decoder.string(forKey: key) }
    func decode(_ type: Double.Type) throws -> Double { try decoder.floating(type, forKey: key) }
    func decode(_ type: Float.Type) throws -> Float { try decoder.floating(type, forKey: key) }
    func decode(_ type: Int.Type) throws -> Int { try decoder.integer(type, forKey: key) }
    func decode(_ type: Int8.Type) throws -> Int8 { try decoder.integer(type, forKey: key) }
    func decode(_ type: Int16.Type) throws -> Int16 { try decoder.integer(type, forKey: key) }
    func decode(_ type: Int32.Type) throws -> Int32 { try decoder.integer(type, forKey: key) }
    func decode(_ type: Int64.Type) throws -> Int64 { try decoder.integer(type, forKey: key) }
    func decode(_ type: UInt.Type) throws -> UInt { try decoder.integer(type, forKey: key) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try decoder.integer(type, forKey: key) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try decoder.integer(type, forKey: key) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try decoder.integer(type, forKey: key) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try decoder.integer(type, forKey: key) }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable { try decoder.decode(type, forKey: key) }
}
