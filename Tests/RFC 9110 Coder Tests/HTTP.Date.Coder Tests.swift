import RFC_5322
import Testing

import RFC_9110
import RFC_9110_Coder

@Suite
struct `HTTP.Date.Coder Tests` {
    @Test
    func `Header value format - IMF-fixdate`() async throws {
        let httpDate = HTTP.Date(secondsSinceEpoch: 784_111_777)

        let field = HTTP.Field(dateTime: httpDate)

        let headerValue = field.value.rawValue

        #expect(headerValue == "Sun, 06 Nov 1994 08:49:37 GMT")
        #expect(headerValue.contains("GMT"))
        #expect(!headerValue.contains("+0000"))
    }

    @Test
    func `Parse IMF-fixdate format`() async throws {
        let field = try HTTP.Field(name: "Date", value: "Sun, 06 Nov 1994 08:49:37 GMT")
        let parsed = RFC_5322.DateTime(field)

        #expect(parsed != nil)

        let expectedTimestamp = 784_111_777
        let diff = abs(parsed!.secondsSinceEpoch - expectedTimestamp)
        #expect(diff < 1)
    }

    @Test
    func `Parse RFC 850 format (obsolete)`() async throws {

        let field = try HTTP.Field(name: "Date", value: "Sunday, 06-Nov-94 08:49:37 GMT")
        let parsed = RFC_5322.DateTime(field)

        #expect(parsed != nil)

        let expectedTimestamp = 784_111_777
        #expect(abs(parsed!.secondsSinceEpoch - expectedTimestamp) < 1)
    }

    @Test
    func `Parse asctime format (obsolete)`() async throws {

        let field = try HTTP.Field(name: "Date", value: "Sun Nov  6 08:49:37 1994")
        let parsed = RFC_5322.DateTime(field)

        #expect(parsed != nil)

        let expectedTimestamp = 784_111_777
        #expect(abs(parsed!.secondsSinceEpoch - expectedTimestamp) < 1)
    }

    @Test
    func `Parse invalid date`() async throws {
        #expect(RFC_5322.DateTime(try HTTP.Field(name: "Date", value: "invalid")) == nil)
        #expect(RFC_5322.DateTime(try HTTP.Field(name: "Date", value: "")) == nil)
        #expect(
            RFC_5322.DateTime(try HTTP.Field(name: "Date", value: "2024-11-16")) == nil
        )
    }

    @Test
    func `Round trip - format and parse`() async throws {
        let original = HTTP.Date(secondsSinceEpoch: 784_111_777)

        let field = HTTP.Field(dateTime: original)
        let parsed = RFC_5322.DateTime(field)

        #expect(parsed != nil)
        let diff = abs(parsed!.secondsSinceEpoch - original.secondsSinceEpoch)
        #expect(diff < 1)
    }
}
