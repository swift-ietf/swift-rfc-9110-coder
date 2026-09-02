import Byte
import Byte_Parser

enum Whitespace {

    static func isWhitespace(_ byte: Byte) -> Bool {
        byte.bitPattern == 0x20 || byte.bitPattern == 0x09
    }

    static func skip(_ input: inout Byte.Input) {
        while let byte = input.first, isWhitespace(byte) {
            _ = input.next()
        }
    }
}

enum Comma {

    static func consume(_ input: inout Byte.Input) -> Bool {
        let start = input.checkpoint
        Whitespace.skip(&input)
        guard let comma = input.next(), comma.bitPattern == 0x2C else {
            input.seek(to: start)
            return false
        }
        Whitespace.skip(&input)
        return true
    }
}
