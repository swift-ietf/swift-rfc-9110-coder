public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Token {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = RFC_9110.Token

        public typealias Failure = RFC_9110.Token.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> RFC_9110.Token {
            var bytes: [UInt8] = []
            while true {
                let mark = input.checkpoint
                guard let byte = input.next(), RFC_9110.Token.isTchar(byte.bitPattern) else {
                    input.seek(to: mark)
                    break
                }
                bytes.append(byte.bitPattern)
            }
            guard !bytes.isEmpty else { throw .empty }
            return RFC_9110.Token(unchecked: String(decoding: bytes, as: UTF8.self))
        }

        public borrowing func serialize(_ output: RFC_9110.Token, into buffer: inout Buffer) throws(Failure) {
            guard !output.rawValue.isEmpty else { throw .empty }
            for byte in output.rawValue.utf8 {
                guard RFC_9110.Token.isTchar(byte) else { throw .invalidCharacter(byte) }
                buffer.append(Byte(bitPattern: byte))
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}
