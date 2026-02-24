import SQLyra
import Testing

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
#else
import FoundationEssentials
#endif

struct SQLParameterTests {

    @Test func literals() {
        #expect(SQLParameter.null == nil)
        #expect(SQLParameter.bool(true) == true)
        #expect(SQLParameter.bool(false) == false)
        #expect(SQLParameter.int64(12) == 12)
        #expect(SQLParameter.integer(100) == 100)
        #expect(SQLParameter.double(1.0) == 1.0)
        #expect(SQLParameter.text("hello") == "hello")
    }

    @Test func description() {
        #expect(SQLParameter.null.description == "null")
        #expect(SQLParameter.bool(false).description == "0")
        #expect(SQLParameter.bool(true).description == "1")
        #expect(SQLParameter.int64(100).description == "100")
        #expect(SQLParameter.double(1.0).description == "1.0")
        #expect(SQLParameter.text("row").description == "row")
        #expect(SQLParameter.blob(Data("abc".utf8)).description == "3 bytes")
    }
}
