import Foundation
import SQLyra
import Testing

struct DatabaseErrorTests {

    @Test func localizedDescription() async throws {
        let error: any Error = DatabaseError(code: 25, message: "A", details: "B")
        #expect(error.localizedDescription == "A")
    }

    @Test func nsError() {
        let error = DatabaseError(code: 12, message: "A", details: "B") as NSError
        #expect(error.domain == "SQLyra.DatabaseErrorDomain")
        #expect(error.code == 12)

        for (key, value) in error.userInfo {
            switch (key, value) {
            case (NSLocalizedDescriptionKey, let string as String):
                #expect(string == "A")
            case (NSLocalizedFailureReasonErrorKey, let string as String):
                #expect(string == "B")
            default:
                Issue.record("Unexpected \(key)=\(value)")
            }
        }
    }

}
