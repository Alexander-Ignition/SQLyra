import Foundation
import SQLite3

open class StatementDecoder {
    open var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    open func decode<T>(_ type: T.Type, from statement: PreparedStatement) throws -> T where T: Decodable {
        let context = _DecodingContext(statement: statement, userInfo: userInfo)
        let decoder = _StatementDecoder(context: context, codingPath: [])
        return try type.init(from: decoder)
    }
}

final class _DecodingContext {
    let statement: PreparedStatement
    let userInfo: [CodingUserInfoKey: Any]

    init(statement: PreparedStatement, userInfo: [CodingUserInfoKey: Any]) {
        self.statement = statement
        self.userInfo = userInfo
    }
}

final class _StatementDecoder: Decoder {
    let context: _DecodingContext
    var userInfo: [CodingUserInfoKey: Any] { context.userInfo }
    var codingPath: [any CodingKey] = []

    init(context: _DecodingContext, codingPath: [any CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = KeyedContainer<Key>(context: context, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(codingPath: codingPath, "`unkeyedContainer()` not supported")
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        guard let key = codingPath.last else {
            throw DecodingError.dataCorrupted(codingPath: codingPath, "key not found")
        }
        return SingleValueContainer(key: key.stringValue, context: context, codingPath: codingPath)
    }
}

extension _StatementDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let context: _DecodingContext
        var codingPath: [any CodingKey]

        var allKeys: [Key] {
            context.statement.columnIndexByName.keys.compactMap { Key(stringValue: $0) }
        }

        func contains(_ key: Key) -> Bool {
            context.statement.columnIndexByName.keys.contains(key.stringValue)
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            context.statement.null(for: key.stringValue)
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            guard let value = context.statement.int64(for: key.stringValue) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath + [key])
            }
            return value != 0
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            guard let value = context.statement.string(for: key.stringValue) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath + [key])
            }
            return value
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            guard let value = context.statement.double(for: key.stringValue) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath + [key])
            }
            return value
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            guard let value = context.statement.double(for: key.stringValue) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath + [key])
            }
            guard let number = Float(exactly: value) else {
                throw DecodingError.numberNotFit(type, value: value.description, path: codingPath + [key])
            }
            return number
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try integer(type, forKey: key)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            try integer(type, forKey: key)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            try integer(type, forKey: key)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            try integer(type, forKey: key)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try integer(type, forKey: key)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try integer(type, forKey: key)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            try integer(type, forKey: key)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            try integer(type, forKey: key)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            try integer(type, forKey: key)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try integer(type, forKey: key)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            // TODO: Data
            let decoder = _StatementDecoder(context: context, codingPath: codingPath + [key])
            return try type.init(from: decoder)
        }

        func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            fatalError()
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            fatalError()
        }

        func superDecoder() throws -> any Decoder {
            fatalError()
        }

        func superDecoder(forKey key: Key) throws -> any Decoder {
            fatalError()
        }

        @inline(__always)
        private func integer<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Numeric {
            guard let value = context.statement.int64(for: key.stringValue) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath + [key])
            }
            guard let number = type.init(exactly: value) else {
                throw DecodingError.numberNotFit(type, value: value.description, path: codingPath + [key])
            }
            return number
        }
    }
}

extension _StatementDecoder {
    struct SingleValueContainer: SingleValueDecodingContainer {
        let key: String
        let context: _DecodingContext
        let codingPath: [any CodingKey]

        func decodeNil() -> Bool {
            context.statement.null(for: key)
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            guard let value = context.statement.int64(for: key) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath)
            }
            return value != 0
        }

        func decode(_ type: String.Type) throws -> String {
            guard let value = context.statement.string(for: key) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath)
            }
            return value
        }

        func decode(_ type: Double.Type) throws -> Double {
            guard let value = context.statement.double(for: key) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath)
            }
            return value
        }

        func decode(_ type: Float.Type) throws -> Float {
            guard let value = context.statement.double(for: key) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath)
            }
            guard let number = Float(exactly: value) else {
                throw DecodingError.numberNotFit(type, value: value.description, path: codingPath)
            }
            return number
        }

        func decode(_ type: Int.Type) throws -> Int {
            try integer(type)
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            try integer(type)
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            try integer(type)
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            try integer(type)
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            try integer(type)
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            try integer(type)
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            try integer(type)
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            try integer(type)
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            try integer(type)
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            try integer(type)
        }

        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            // TODO: Data
            let decoder = _StatementDecoder(context: context, codingPath: codingPath)
            return try type.init(from: decoder)
        }

        @inline(__always)
        private func integer<T>(_ type: T.Type) throws -> T where T: Numeric {
            guard let value = context.statement.int64(for: key) else {
                throw DecodingError.valueNotFound(type, codingPath: codingPath)
            }
            guard let number = type.init(exactly: value) else {
                throw DecodingError.numberNotFit(type, value: value.description, path: codingPath)
            }
            return number
        }
    }
}

extension DecodingError {
    fileprivate static func valueNotFound(_ type: Any.Type, codingPath: [any CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        return DecodingError.valueNotFound(type, context)
    }

    fileprivate static func numberNotFit(_ type: Any.Type, value: String, path: [any CodingKey]) -> DecodingError {
        dataCorrupted(codingPath: path, "Parsed JSON number <\(value)> does not fit in \(type).")
    }

    fileprivate static func dataCorrupted(codingPath: [any CodingKey], _ message: String) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: message)
        return DecodingError.dataCorrupted(context)
    }
}
