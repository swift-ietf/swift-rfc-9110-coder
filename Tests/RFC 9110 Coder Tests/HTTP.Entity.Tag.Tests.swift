import Foundation
import RFC_9110
import RFC_9110_Coder
import Testing

@Suite
struct `HTTP.Entity.Tag.Coder Tests` {

    @Test
    func `Parse strong ETag`() async throws {
        let parsed = HTTP.Entity.Tag.parse("\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == false)
    }

    @Test
    func `Parse weak ETag`() async throws {
        let parsed = HTTP.Entity.Tag.parse("W/\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == true)
    }

    @Test
    func `Parse invalid ETag`() async throws {
        #expect(HTTP.Entity.Tag.parse("invalid") == nil)
        #expect(HTTP.Entity.Tag.parse("") == nil)
        #expect(HTTP.Entity.Tag.parse("abc123") == nil)
    }

    @Test
    func `Codable - strong`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.Entity.Tag.strong("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.Entity.Tag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test
    func `Codable - weak`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.Entity.Tag.weak("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.Entity.Tag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test
    func `String literal`() async throws {
        let strong = try #require(HTTP.Entity.Tag("\"abc\""))
        #expect(strong.value == "abc")
        #expect(strong.isWeak == false)

        let weak = try #require(HTTP.Entity.Tag("W/\"abc\""))
        #expect(weak.value == "abc")
        #expect(weak.isWeak == true)
    }

}
