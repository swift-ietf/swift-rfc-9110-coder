public import Byte
import Byte
public import Cursor
public import Coder
public import Cursor
public import RFC_9110
import Parser
import Serializer

extension RFC_9110 {

    public enum QuotedString {}
}

extension RFC_9110.QuotedString {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = String

        public typealias Failure = RFC_9110.QuotedString.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> String {
            let start = input.checkpoint
            guard let open = input.next(), open.bitPattern == 0x22 else {
                input.seek(to: start)
                throw .expectedOpenQuote
            }

            var bytes: [UInt8] = []

            while let byte = input.next() {
                if byte.bitPattern == 0x22 {
                    return String(decoding: bytes, as: UTF8.self)
                }

                if byte.bitPattern == 0x5C {
                    guard let escaped = input.next() else {
                        throw .unexpectedEndOfInput
                    }
                    guard Self.isQuotedPair(escaped) else {
                        throw .invalidEscapeSequence
                    }
                    bytes.append(escaped.bitPattern)
                    continue
                }

                bytes.append(byte.bitPattern)
            }

            throw .unexpectedEndOfInput
        }

        public borrowing func serialize(_ output: String, into buffer: inout Buffer) throws(Failure) {
            buffer.append(Byte(bitPattern: 0x22))
            for byte in output.utf8 {
                switch byte {
                case 0x22, 0x5C:
                    buffer.append(Byte(bitPattern: 0x5C))
                    buffer.append(Byte(bitPattern: byte))

                case 0x09, 0x20...0x7E, 0x80...:
                    buffer.append(Byte(bitPattern: byte))

                default:
                    throw .invalidCharacter(Byte(bitPattern: byte))
                }
            }
            buffer.append(Byte(bitPattern: 0x22))
        }

        static func isQuotedPair(_ byte: Byte) -> Bool {
            byte.bitPattern == 0x09 || (0x20...0x7E).contains(byte.bitPattern) || byte.bitPattern >= 0x80
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedOpenQuote
        case unexpectedEndOfInput
        case invalidEscapeSequence
        case invalidCharacter(Byte)
    }
}
