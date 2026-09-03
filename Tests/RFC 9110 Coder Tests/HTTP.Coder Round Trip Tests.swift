import Byte
import Byte_Standard_Library_Integration
import Cursor_Standard_Library_Integration
import Coder
import Parser
import RFC_9110
import RFC_9110_Coder
import Serializer
import Testing

@Suite
struct `HTTP.Coder Round Trip Tests` {

    @Test
    func `A media type with parameters round-trips`() throws {
        let mediaType = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])
        var bytes: [Byte] = []
        try mediaType.encode(into: &bytes)
        #expect(bytes == "text/html; charset=utf-8".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        let decoded = try HTTP.MediaType(decoding: &input)
        #expect(decoded == mediaType)
        #expect(decoded.parameters == mediaType.parameters)
        #expect(input.isEmpty)
    }

    @Test
    func `An entity tag round-trips in both strengths`() throws {
        for tag in [HTTP.Entity.Tag.strong("abc"), HTTP.Entity.Tag.weak("abc")] {
            var bytes: [Byte] = []
            try tag.encode(into: &bytes)
            #expect(bytes == tag.headerValue.utf8.map(Byte.init(bitPattern:)))

            var input = bytes[...]
            #expect(try HTTP.Entity.Tag(decoding: &input) == tag)
        }
    }

    @Test
    func `A quality value round-trips through its canonical spelling`() throws {
        for thousandths in [0, 1, 100, 500, 999, 1000] {
            let quality = try #require(HTTP.Message.Content.Negotiation.QualityValue(thousandths))
            var bytes: [Byte] = []
            try quality.encode(into: &bytes)

            var input = bytes[...]
            #expect(try HTTP.Message.Content.Negotiation.QualityValue(decoding: &input) == quality)
            #expect(input.isEmpty)
        }
    }

    @Test
    func `A media type preference serializes its weight only when it is not the default`() throws {
        let plain = HTTP.Message.Content.Negotiation.MediaTypePreference(mediaType: .json)
        var bytes: [Byte] = []
        try plain.encode(into: &bytes)
        #expect(bytes == "application/json".utf8.map(Byte.init(bitPattern:)))

        let weighted = HTTP.Message.Content.Negotiation.MediaTypePreference(
            mediaType: .json,
            quality: try #require(HTTP.Message.Content.Negotiation.QualityValue(900))
        )
        bytes = []
        try weighted.encode(into: &bytes)
        #expect(bytes == "application/json;q=0.9".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        let decoded = try HTTP.Message.Content.Negotiation.MediaTypePreference(decoding: &input)
        #expect(decoded == weighted)
    }

    @Test
    func `A charset preference is a weighted token`() throws {
        var input = [Byte](utf8: "utf-8;q=0.5")[...]
        let preference = try HTTP.Message.Content.Negotiation.CharsetPreference(decoding: &input)
        #expect(preference.charset == "utf-8")
        #expect(preference.quality.thousandths == 500)

        var bytes: [Byte] = []
        try preference.encode(into: &bytes)
        #expect(bytes == "utf-8;q=0.5".utf8.map(Byte.init(bitPattern:)))
    }

    @Test
    func `A challenge round-trips its parameters`() throws {
        let challenge = HTTP.Authentication.Challenge(
            scheme: .bearer,
            parameters: ["realm": "example", "scope": "read write"]
        )
        var bytes: [Byte] = []
        try challenge.encode(into: &bytes)
        #expect(bytes == "Bearer realm=example, scope=\"read write\"".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        #expect(try HTTP.Authentication.Challenge(decoding: &input) == challenge)
    }

    @Test
    func `Credentials round-trip`() throws {
        let credentials = HTTP.Authentication.Credentials.bearer("token123")
        var bytes: [Byte] = []
        try credentials.encode(into: &bytes)
        #expect(bytes == "Bearer token123".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        #expect(try HTTP.Authentication.Credentials(decoding: &input) == credentials)
    }

    @Test
    func `Preconditions parse entity tag lists and wildcards`() throws {
        let list = HTTP.Precondition.parseIfMatch("\"a\", W/\"b\"")
        #expect(list == .ifMatch([.strong("a"), .weak("b")]))

        #expect(HTTP.Precondition.parseIfNoneMatch(" * ") == .ifNoneMatch([HTTP.Precondition.wildcardTag]))
        #expect(HTTP.Precondition.parseIfMatch("nonsense") == nil)
    }
}
