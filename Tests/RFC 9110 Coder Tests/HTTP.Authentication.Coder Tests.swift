import Foundation
import RFC_9110
import RFC_9110_Coder
import Testing

@Suite
struct `HTTP.Authentication.Coder Tests` {

    @Test
    func `Challenge parsing - scheme only`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters.isEmpty == true)
    }

    @Test
    func `Challenge parsing - with parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic realm=\"API Access\"")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters["realm"] == "API Access")
    }

    @Test
    func `Challenge parsing - multiple parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse(
            "Bearer realm=\"example\", scope=\"read write\""
        )

        #expect(challenge?.scheme == .bearer)
        #expect(challenge?.parameters["realm"] == "example")
        #expect(challenge?.parameters["scope"] == "read write")
    }

    @Test
    func `Credentials parsing`() async throws {
        let creds = HTTP.Authentication.Credentials.parse("Bearer abc123")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test
    func `Credentials parsing - with whitespace`() async throws {
        let creds = HTTP.Authentication.Credentials.parse("  Bearer   abc123  ")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test
    func `Credentials parsing - invalid`() async throws {
        let invalid = HTTP.Authentication.Credentials.parse("InvalidFormat")

        #expect(invalid == nil)
    }

}
