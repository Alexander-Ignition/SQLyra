import Foundation
import SQLite3

/// SQLite database error.
public struct DatabaseError: Error, Equatable, Hashable {
    /// Failed result code.
    public let code: Int32

    /// A short error description.
    public let message: String?

    /// A complete sentence (or more) describing why the operation failed.
    public let details: String?

    /// A new database error.
    ///
    /// - Parameters:
    ///   - code: failed result code.
    ///   - message: A short error description.
    ///   - details: A complete sentence (or more) describing why the operation failed.
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

// MARK: - CustomNSError

extension DatabaseError: CustomNSError {
    public static let errorDomain = "SQLyra.DatabaseErrorDomain"

    public var errorCode: Int { Int(code) }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = message
        userInfo[NSLocalizedFailureReasonErrorKey] = details
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
