public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Authentication.Credentials {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Authentication.Credentials

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Authentication.Credentials.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> Output {
            Whitespace.skip(&input)

            let scheme: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                scheme = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                throw .expectedScheme(error)
            }

            guard let separator = input.first, Whitespace.isWhitespace(separator) else {
                throw .expectedToken
            }
            Whitespace.skip(&input)

            var bytes: [UInt8] = []
            while let byte = input.next() {
                bytes.append(byte.bitPattern)
            }
            while let last = bytes.last, last == 0x20 || last == 0x09 {
                bytes.removeLast()
            }
            guard !bytes.isEmpty else { throw .expectedToken }

            return Output(
                scheme: .init(scheme.rawValue),
                token: String(decoding: bytes, as: UTF8.self)
            )
        }

        public borrowing func serialize(_ output: Output, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.scheme.name.utf8.lazy.map(Byte.init(bitPattern:)))
            buffer.append(Byte(bitPattern: 0x20))
            buffer.append(contentsOf: output.token.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Authentication.Credentials: Coder.Codable {}

extension RFC_9110.Authentication.Credentials.Coder {

    public enum Error: Swift.Error, Equatable {
        case expectedScheme(RFC_9110.Token.Error)
        case expectedToken
    }
}

extension RFC_9110.Authentication.Credentials {

    public static func parse(_ headerValue: String) -> Self? {
        var input = Byte.Input(utf8: headerValue)
        do throws(Coder.Error) {
            return try Coder().parse(&input)
        } catch {
            return nil
        }
    }
}
