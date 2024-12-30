import Foundation
import SQLite3

/// SQLite database error.
public struct DatabaseError: Error, Equatable, Hashable {
    /// Failed result code.
    public let code: Int32

    /// A short error description.
    public var message: String?

    /// A complete sentence (or more) describing why the operation failed.
    public let details: String?

    /// A new database error.
    ///
    /// - Parameters:
    ///   - code: failed result code.
    ///   - message: A short error description.
    ///   - reason: A complete sentence (or more) describing why the operation failed.
    public init(code: Int32, message: String, details: String) {
        self.code = code
        self.message = message
        self.details = details
    }

    init(code: Int32, db: OpaquePointer?) {
        self.code = code
        self.message = sqlite3_errstr(code).string
        let details = sqlite3_errmsg(db).string
        self.details = details == message ? nil : details
    }
}

// MARK: - LocalizedError

extension DatabaseError: LocalizedError {
    public var errorDescription: String? { message }
    public var failureReason: String? { details }
}

// MARK: - CustomNSError

extension DatabaseError: CustomNSError {
    public static let errorDomain = "SQLyra.DatabaseError"

    public var errorCode: Int { Int(code) }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        return userInfo
    }
}

// MARK: - DatabaseHandle

protocol DatabaseHandle {
    var db: OpaquePointer! { get }
}

extension DatabaseHandle {
    @discardableResult
    func check(_ code: Int32, _ success: Int32 = SQLITE_OK) throws -> Self {
        guard code == success else {
            throw DatabaseError(code: code, db: db)
        }
        return self
    }
}
