import Pair
public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Either
import Parser
import Serializer

extension RFC_9110.Authentication.Credentials {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Authentication.Credentials.Error

        public init() {}

        @Coder::Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Authentication.Credentials, Buffer, Failure> {
            Coder::Coder(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                RFC_9110.Token.Coder()
                RFC_9110.RWS.Coder()
                RFC_9110.Authentication.Credentials.Remainder.Coder()
            }
            .map(
                to: { output in
                    RFC_9110.Authentication.Credentials(scheme: .init(output.first.rawValue), token: output.second)
                },
                from: { .init(RFC_9110.Token(unchecked: $0.scheme.name), $0.token) }
            )
            .mapFailure { (failure) -> Failure in
                switch failure {
                case .left(.left(let error)): .expectedScheme(error)
                default: .expectedToken
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedScheme(RFC_9110.Token.Error)
        case expectedToken
    }
}


extension RFC_9110.Authentication.Credentials {

    public static func parse(_ headerValue: String) -> Self? {
        var input = [Byte](utf8: headerValue)[...]
        do throws(Error) {
            return try coder.parse(&input)
        } catch {
            return nil
        }
    }
}

extension RFC_9110.Authentication.Credentials {

    enum Remainder {}
}

extension RFC_9110.Authentication.Credentials.Remainder {

    struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        typealias Output = String

        typealias Failure = RFC_9110.Authentication.Credentials.Remainder.Error

        borrowing func parse(_ input: inout Input) throws(Failure) -> String {
            var bytes: [UInt8] = []
            while let byte = input.next() {
                bytes.append(byte.bitPattern)
            }
            while let last = bytes.last, last == 0x20 || last == 0x09 {
                bytes.removeLast()
            }
            guard !bytes.isEmpty else { throw .empty }
            return String(decoding: bytes, as: UTF8.self)
        }

        borrowing func serialize(_ output: String, into buffer: inout Buffer) throws(Failure) {
            guard !output.isEmpty else { throw .empty }
            buffer.append(contentsOf: output.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }

    enum Error: Swift.Error, Equatable {
        case empty
    }
}
