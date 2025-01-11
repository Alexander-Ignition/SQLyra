import SQLyra
import Testing

extension SQLParameter: CustomTestStringConvertible {
    public var testDescription: String {
        switch self {
        case .null: "NULL"
        case .int64(let value): "INT(\(value))"
        case .double(let value): "DOUBLE(\(value))"
        case .text(let value): "TEXT(\(value))"
        case .blob(let value): "BLOB(\(Array(value))"
        }
    }
}

extension SQLParameter: CustomTestArgumentEncodable {
    public func encodeTestArgument(to encoder: some Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .int64(let value):
            try value.encode(to: encoder)
        case .double(let value):
            try value.encode(to: encoder)
        case .text(let value):
            try value.encode(to: encoder)
        case .blob(let value):
            try value.encode(to: encoder)
        }
    }
}
