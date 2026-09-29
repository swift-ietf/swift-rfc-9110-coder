import Testing

import RFC_9110
import RFC_9110_Coder

@Suite
struct `HTTP.Negotiation.Vary.Coder Tests` {

    @Test
    func `Parse field names`() async throws {
        let parsed = HTTP.Negotiation.Vary.parse("Accept-Encoding, User-Agent")

        #expect(parsed != nil)
        #expect(parsed?.fieldNames == ["accept-encoding", "user-agent"])
        #expect(parsed?.variesOnAllAspects == false)
    }

    @Test
    func `Parse all aspects`() async throws {
        let parsed = HTTP.Negotiation.Vary.parse("*")

        #expect(parsed != nil)
        #expect(parsed?.variesOnAllAspects == true)
    }

    @Test
    func `Parse with whitespace`() async throws {
        let parsed = HTTP.Negotiation.Vary.parse("  Accept-Encoding ,  User-Agent  ")

        #expect(parsed != nil)
        #expect(parsed?.fieldNames == ["accept-encoding", "user-agent"])
    }

    @Test
    func `Parse empty string`() async throws {
        #expect(HTTP.Negotiation.Vary.parse("") == nil)
        #expect(HTTP.Negotiation.Vary.parse("  ") == nil)
    }

    @Test
    func `LosslessStringConvertible`() async throws {
        let vary = HTTP.Negotiation.Vary("Accept-Encoding, User-Agent")

        #expect(vary != nil)
        #expect(vary?.fieldNames == ["accept-encoding", "user-agent"])
    }

    @Test
    func `Round trip - format and parse`() async throws {
        let original = HTTP.Negotiation.Vary(fieldNames: ["Accept-Encoding", "User-Agent"])
        let headerValue = original.headerValue
        let parsed = HTTP.Negotiation.Vary.parse(headerValue)

        #expect(parsed != nil)
        #expect(parsed == original)
    }
}
