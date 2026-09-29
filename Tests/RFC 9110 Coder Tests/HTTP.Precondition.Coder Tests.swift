import RFC_5322
import Testing

import RFC_9110
import RFC_9110_Coder

@Suite
struct `HTTP.Precondition.Coder Tests` {

    @Test
    func `Parse If-Modified-Since as an HTTP-date`() async throws {
        let precondition = HTTP.Precondition.parseIfModifiedSince("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(precondition == .ifModifiedSince(HTTP.Date(secondsSinceEpoch: 784_111_777)))
    }

    @Test
    func `Parse If-Unmodified-Since as an HTTP-date`() async throws {
        let precondition = HTTP.Precondition.parseIfUnmodifiedSince("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(precondition == .ifUnmodifiedSince(HTTP.Date(secondsSinceEpoch: 784_111_777)))
    }

    @Test
    func `Parse If-Range as an HTTP-date`() async throws {
        let precondition = HTTP.Precondition.parseIfRange("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(precondition == .ifRange(.lastModified(HTTP.Date(secondsSinceEpoch: 784_111_777))))
    }

    @Test
    func `Parse If-Range as an entity tag`() async throws {
        let precondition = HTTP.Precondition.parseIfRange("\"xyzzy\"")

        #expect(precondition == .ifRange(.entityTag(.strong("xyzzy"))))
    }

    @Test
    func `Serialize a date precondition as an IMF-fixdate`() async throws {
        let precondition = HTTP.Precondition.ifModifiedSince(HTTP.Date(secondsSinceEpoch: 784_111_777))

        #expect(precondition.headerValue == "Sun, 06 Nov 1994 08:49:37 GMT")
        #expect(precondition.description == "If-Modified-Since: Sun, 06 Nov 1994 08:49:37 GMT")
    }

    @Test
    func `Round trip a date precondition`() async throws {
        let original = HTTP.Precondition.ifUnmodifiedSince(HTTP.Date(secondsSinceEpoch: 784_111_777))

        #expect(HTTP.Precondition.parseIfUnmodifiedSince(original.headerValue) == original)
    }

    @Test
    func `Parse an invalid date`() async throws {
        #expect(HTTP.Precondition.parseIfModifiedSince("not a date") == nil)
        #expect(HTTP.Precondition.parseIfUnmodifiedSince("") == nil)
    }
}
