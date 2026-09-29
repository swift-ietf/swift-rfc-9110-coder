public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Negotiation.QualityValue {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = RFC_9110.Negotiation.QualityValue

        public typealias Failure = RFC_9110.Negotiation.QualityValue.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint

            guard let leading = input.next() else {
                input.seek(to: start)
                throw .invalidQValue
            }
            let integer = leading.bitPattern
            guard integer == 0x30 || integer == 0x31 else {
                input.seek(to: start)
                throw .invalidQValue
            }

            let afterInteger = input.checkpoint
            guard let point = input.next(), point.bitPattern == 0x2E else {
                input.seek(to: afterInteger)
                return integer == 0x31 ? .default : .zero
            }

            var fraction = 0
            var digits = 0
            while digits < 3, let digit = Self.digit(&input) {
                fraction = fraction * 10 + digit
                digits += 1
            }

            if Self.digit(&input) != nil {
                input.seek(to: start)
                throw .invalidQValue
            }

            while digits < 3 {
                fraction *= 10
                digits += 1
            }

            if integer == 0x31 {
                guard fraction == 0 else {
                    input.seek(to: start)
                    throw .invalidQValue
                }
                return .default
            }

            guard let quality = Output(fraction) else {
                input.seek(to: start)
                throw .invalidQValue
            }
            return quality
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            buffer.append(contentsOf: output.description.utf8.lazy.map(Byte.init(bitPattern:)))
        }

        private static func digit(_ input: inout Input) -> Int? {
            let mark = input.checkpoint
            guard let byte = input.next(), (0x30...0x39).contains(byte.bitPattern) else {
                input.seek(to: mark)
                return nil
            }
            return Int(byte.bitPattern - 0x30)
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case invalidQValue
    }
}


extension RFC_9110.Negotiation.QualityValue {

    public static func parse(_ string: String) -> Self? {
        var input = [Byte](utf8: string)[...]
        do throws(Error) {
            let quality = try coder.parse(&input)
            guard input.isEmpty else { return nil }
            return quality
        } catch {
            return nil
        }
    }
}
