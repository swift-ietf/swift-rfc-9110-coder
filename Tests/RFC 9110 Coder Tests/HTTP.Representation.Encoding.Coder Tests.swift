import Foundation
import RFC_9110
import RFC_9110_Coder
import Testing

@Suite
struct `HTTP.Representation.Encoding.Coder Tests` {

    @Test
    func `Parse single encoding`() async throws {
        let encodings = HTTP.Representation.Encoding.parse("gzip")

        #expect(encodings.count == 1)
        #expect(encodings[0] == .gzip)
    }

    @Test
    func `Parse multiple encodings`() async throws {
        let encodings = HTTP.Representation.Encoding.parse("gzip, deflate")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .deflate)
    }

    @Test
    func `Parse with whitespace`() async throws {
        let encodings = HTTP.Representation.Encoding.parse(" gzip ,  br  ")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .brotli)
    }

    @Test
    func `Parse empty string`() async throws {
        let encodings = HTTP.Representation.Encoding.parse("")

        #expect(encodings.isEmpty)
    }

}
