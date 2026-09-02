import Foundation
import RFC_9110
import RFC_9110_Coder
import Testing

@Suite
struct `HTTP.MediaType.Coder Tests` {

    @Test
    func `Media type parsing - simple`() async throws {
        let mt = HTTP.MediaType.parse("application/json")

        #expect(mt?.type == "application")
        #expect(mt?.subtype == "json")
        #expect(mt?.parameters.isEmpty == true)
    }

    @Test
    func `Media type parsing - with parameters`() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=utf-8")

        #expect(mt?.type == "text")
        #expect(mt?.subtype == "html")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - multiple parameters`() async throws {
        let mt = HTTP.MediaType.parse(
            "multipart/form-data; boundary=----WebKitFormBoundary; charset=utf-8"
        )

        #expect(mt?.type == "multipart")
        #expect(mt?.subtype == "form-data")
        #expect(mt?.parameters["boundary"] == "----WebKitFormBoundary")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - quoted parameter`() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=\"utf-8\"")

        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - invalid`() async throws {
        #expect(HTTP.MediaType.parse("invalid") == nil)
        #expect(HTTP.MediaType.parse("") == nil)
        #expect(HTTP.MediaType.parse("/json") == nil)
        #expect(HTTP.MediaType.parse("application/") == nil)
    }

    @Test
    func `Media type matching - exact`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/json"))
        #expect(!json.matches("text/html"))
    }

    @Test
    func `Media type matching - wildcard subtype`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/*"))
        #expect(!json.matches("text/*"))
    }

    @Test
    func `Media type matching - wildcard all`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("*/*"))
    }

    @Test
    func `Media type codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.MediaType.json)
        let decoded = try decoder.decode(HTTP.MediaType.self, from: encoded)

        #expect(decoded == .json)
    }

    @Test
    func `Media type string literal`() async throws {
        let json = try #require(HTTP.MediaType("application/json"))

        #expect(json == .json)
    }

}
