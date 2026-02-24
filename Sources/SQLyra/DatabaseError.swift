import SQLite3

/// SQLite database error.
public struct DatabaseError: Error, Equatable, Hashable {
    /// Failed result code.
    public let code: Int32

    /// The  English-language text that describes the result `code`, as UTF-8, or `nil`.
    public var codeDescription: String? { sqlite3_errstr(code).string }

    /// The text that describes the error or `nil` if no error message is available.
    public let message: String?

    /// A new database error.
    ///
    /// - Parameters:
    ///   - code: failed result code.
    ///   - message: The text that describes the error or `nil` if no error message is available.
    public init(code: Int32, message: String?) {
        self.code = code
        self.message = message
    }
}

extension Database {
    private var errorMessage: String? { sqlite3_errmsg(db).string }

    func error(code: Int32) -> DatabaseError {
        DatabaseError(code: code, message: errorMessage)
    }

    @discardableResult
    func check(_ code: Int32, _ success: Int32 = SQLITE_OK) throws(DatabaseError) -> Database {
        guard code == success else {
            throw error(code: code)
        }
        return self
    }
}

// MARK: - DatabaseError + Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

import Foundation

extension DatabaseError: CustomNSError {
    public static let errorDomain = "SQLyra.DatabaseErrorDomain"

    public var errorCode: Int { Int(code) }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = codeDescription
        userInfo[NSLocalizedFailureReasonErrorKey] = message
        return userInfo
    }
}

#endif
