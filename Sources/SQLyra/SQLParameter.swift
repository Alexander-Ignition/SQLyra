#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
#else
import FoundationEssentials
#endif

/// SQL parameters.
public enum SQLParameter: Equatable, Sendable {
    case null

    /// 64-bit signed integer.
    case int64(Int64)

    /// 64-bit IEEE floating point number.
    case double(Double)

    /// UTF-8 string.
    case text(String)

    /// Binary Large Object.
    case blob(Data)

    public static func bool(_ value: Bool) -> SQLParameter {
        SQLParameter.int64(value ? 1 : 0)
    }

    @inlinable
    public static func integer<T: SignedInteger>(_ value: T) -> SQLParameter {
        SQLParameter.int64(Int64(value))
    }
}

// MARK: - CustomStringConvertible

extension SQLParameter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: "null"
        case .int64(let value): value.description
        case .double(let value): value.description
        case .text(let value): value.description
        case .blob(let value): value.description
        }
    }
}

// MARK: - Literals

extension SQLParameter: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

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
