import Byte
import Cursor
import Coder
import Parser
import RFC_9110
import RFC_9110_Coder
import Serializer
import Testing

@Suite
struct `HTTP.Token.Coder Tests` {

    @Test
    func `A token round-trips through bytes`() throws {
        let token = try HTTP.Token("chunked")
        var bytes: [Byte] = []
        try HTTP.Token.coder.serialize(token, into: &bytes)
        var input = bytes[...]

        #expect(try HTTP.Token.coder.parse(&input) == token)
        #expect(input.isEmpty)
    }

    @Test
    func `A token stops at the first delimiter`() throws {
        var input = [Byte](utf8: "text/html")[...]
        let token = try HTTP.Token.coder.parse(&input)

        #expect(token.rawValue == "text")
        #expect(input.first?.bitPattern == 0x2F)
    }

    @Test
    func `An empty token is refused`() {
        var input = [Byte](utf8: " x")[...]

        #expect(throws: HTTP.Token.Error.empty) {
            try HTTP.Token.coder.parse(&input)
        }
    }

    @Test
    func `A validating initialiser rejects delimiters`() {
        #expect(throws: HTTP.Token.Error.invalidCharacter(0x2F)) {
            try HTTP.Token("text/html")
        }
    }

    @Test
    func `A quoted string round-trips with escapes`() throws {
        let text = "say \"hi\" \\ there"
        var bytes: [Byte] = []
        try HTTP.QuotedString.coder.serialize(text, into: &bytes)
        #expect(bytes == "\"say \\\"hi\\\" \\\\ there\"".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        #expect(try HTTP.QuotedString.coder.parse(&input) == text)
        #expect(input.isEmpty)
    }

    @Test
    func `A quoted string must close`() {
        var input = [Byte](utf8: "\"open")[...]

        #expect(throws: HTTP.QuotedString.Error.unexpectedEndOfInput) {
            try HTTP.QuotedString.coder.parse(&input)
        }
    }

    @Test
    func `A parameter serializes as a token when it can and quotes otherwise`() throws {
        let plain = HTTP.Parameter(name: try HTTP.Token("charset"), value: "utf-8")
        var bytes: [Byte] = []
        try HTTP.Parameter.coder.serialize(plain, into: &bytes)
        #expect(bytes == "charset=utf-8".utf8.map(Byte.init(bitPattern:)))

        let spaced = HTTP.Parameter(name: try HTTP.Token("realm"), value: "API Access")
        bytes = []
        try HTTP.Parameter.coder.serialize(spaced, into: &bytes)
        #expect(bytes == "realm=\"API Access\"".utf8.map(Byte.init(bitPattern:)))

        var input = bytes[...]
        #expect(try HTTP.Parameter.coder.parse(&input) == spaced)
    }

    @Test
    func `A field value list tolerates empty elements and surrounding whitespace`() {
        #expect(HTTP.Field.Value.tokens(in: " gzip ,, br , ") == ["gzip", "br"])
        #expect(HTTP.Field.Value.tokens(in: "").isEmpty)
    }

    @Test
    func `Directives carry optional values`() {
        let directives = HTTP.Field.Value.directives(in: "max-age=60, no-cache, private=\"x, y\"")

        #expect(directives.count == 3)
        #expect(directives[0].name == "max-age")
        #expect(directives[0].value == "60")
        #expect(directives[1].name == "no-cache")
        #expect(directives[1].value == nil)
        #expect(directives[2].value == "x, y")
    }

    @Test
    func `A field value list serializes with comma and space`() throws {
        let list = HTTP.Field.Value.List(HTTP.Token.coder)
        var bytes: [Byte] = []
        try list.serialize([try HTTP.Token("gzip"), try HTTP.Token("br")], into: &bytes)

        #expect(bytes == "gzip, br".utf8.map(Byte.init(bitPattern:)))
    }
}


extension `HTTP.Token.Coder Tests` {
    @Test func `malformed field elements do not terminate a list successfully`() {
        var input = [Byte](utf8: "ok,=invalid")[...]
        #expect(throws: HTTP.Field.Value.List<HTTP.Token.Coder<ArraySlice<Byte>, [Byte]>>.Error.self) {
            try HTTP.Field.Value.List(HTTP.Token.coder).parse(&input)
        }
    }

    @Test func `empty field lists do not invoke an element parser`() throws {
        var input = [Byte](utf8: " ")[...]
        let result = try HTTP.Field.Value.List(HTTP.Token.coder).parse(&input)
        #expect(result.isEmpty)
    }
}
