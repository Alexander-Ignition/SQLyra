import Foundation

/// SQL parameters.
public enum SQLParameter {
    /// 64-bit signed integer.
    case int64(Int64)

    /// 64-bit IEEE floating point number.
    case double(Double)

    /// UTF-8 string.
    case text(String)

    /// Binary data.
    case blob(Data)

    public static func bool(_ value: Bool) -> SQLParameter {
        SQLParameter.int64(value ? 1 : 0)
    }

    public static func int(_ value: Int) -> SQLParameter {
        SQLParameter.int64(Int64(value))
    }
}

// MARK: - CustomStringConvertible

extension SQLParameter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int64(let value):
            return value.description
        case .double(let value):
            return value.description
        case .text(let value):
            return value.description
        case .blob(let value):
            return value.description
        }
    }
}

// MARK: - Literals

extension SQLParameter: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension SQLParameter: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self = .int64(value)
    }
}

extension SQLParameter: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension SQLParameter: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .text(value)
    }
}
