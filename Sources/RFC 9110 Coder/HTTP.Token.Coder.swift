public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Token {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Token

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Token.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> RFC_9110.Token {
            var bytes: [UInt8] = []
            while true {
                let checkpoint = input.checkpoint
                guard let byte = input.next() else { break }
                guard RFC_9110.Token.isTchar(byte.bitPattern) else {
                    input.seek(to: checkpoint)
                    break
                }
                bytes.append(byte.bitPattern)
            }
            guard !bytes.isEmpty else { throw .empty }
            return RFC_9110.Token(unchecked: String(decoding: bytes, as: UTF8.self))
        }

        public borrowing func serialize(_ output: RFC_9110.Token, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.rawValue.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Token: Coder.Codable {}
