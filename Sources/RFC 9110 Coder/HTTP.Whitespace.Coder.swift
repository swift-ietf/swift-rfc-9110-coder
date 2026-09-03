public import Byte
public import Coder
public import Cursor
public import RFC_9110
import Parser
import Serializer

extension RFC_9110 {

    public enum OWS {}

    public enum RWS {}
}

extension RFC_9110.OWS {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = Void

        public typealias Failure = Never

        public let canonical: [Byte]

        public init(canonical: [Byte] = []) {
            self.canonical = canonical
        }

        public borrowing func parse(_ input: inout Input) {
            _ = Whitespace.skip(&input)
        }

        public borrowing func serialize(_ output: Void, into buffer: inout Buffer) {
            buffer.append(contentsOf: canonical)
        }
    }
}

extension RFC_9110.RWS {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = Void

        public typealias Failure = Error

        public let canonical: [Byte]

        public init(canonical: [Byte] = [Byte(bitPattern: 0x20)]) {
            self.canonical = canonical
        }

        public borrowing func parse(_ input: inout Input) throws(Error) {
            guard Whitespace.skip(&input) > 0 else { throw .expectedWhitespace }
        }

        public borrowing func serialize(_ output: Void, into buffer: inout Buffer) throws(Failure) {
            buffer.append(contentsOf: canonical)
        }
    }

    public enum Error: Swift.Error, Equatable {
        case expectedWhitespace
    }
}

enum Whitespace {

    static func isWhitespace(_ byte: Byte) -> Bool {
        byte.bitPattern == 0x20 || byte.bitPattern == 0x09
    }

    static func skip<Input: Cursor.`Protocol`<Byte, Never>>(_ input: inout Input) -> Int {
        var count = 0
        while true {
            let mark = input.checkpoint
            guard let byte = input.next(), isWhitespace(byte) else {
                input.seek(to: mark)
                return count
            }
            count += 1
        }
    }
}
