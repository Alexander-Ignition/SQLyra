import SQLyra
import Testing

struct DatabaseErrorTests {

    @Test func codeDescription() {
        let error = DatabaseError(code: 25, message: "B")
        #expect(error.codeDescription == "column index out of range")
    }
}

// MARK: - Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

import Foundation

extension DatabaseErrorTests {

    @Test func localizedDescription() {
        let error: any Error = DatabaseError(code: 25, message: "B")
        #expect(error.localizedDescription == "column index out of range")
    }

    @Test func nsError() {
        let error = DatabaseError(code: 12, message: "B") as NSError
        #expect(error.domain == "SQLyra.DatabaseErrorDomain")
        #expect(error.code == 12)

        for (key, value) in error.userInfo {
            switch (key, value) {
            case (NSLocalizedDescriptionKey, let string as String):
                #expect(string == "unknown operation")
            case (NSLocalizedFailureReasonErrorKey, let string as String):
                #expect(string == "B")
            default:
                Issue.record("Unexpected \(key)=\(value)")
            }
        }
    }
}

#endif
