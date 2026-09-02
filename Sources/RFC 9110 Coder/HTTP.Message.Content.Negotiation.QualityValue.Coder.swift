public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Message.Content.Negotiation.QualityValue {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Message.Content.Negotiation.QualityValue

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> Output {
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
            while digits < 3, let digit = input.first, (0x30...0x39).contains(digit.bitPattern) {
                _ = input.next()
                fraction = fraction * 10 + Int(digit.bitPattern - 0x30)
                digits += 1
            }

            if let extra = input.first, (0x30...0x39).contains(extra.bitPattern) {
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

        public borrowing func serialize(_ output: Output, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.description.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Message.Content.Negotiation.QualityValue: Coder.Codable {}

extension RFC_9110.Message.Content.Negotiation.QualityValue.Coder {

    public enum Error: Swift.Error, Equatable {
        case invalidQValue
    }
}

extension RFC_9110.Message.Content.Negotiation.QualityValue {

    public static func parse(_ string: String) -> Self? {
        var input = Byte.Input(utf8: string)
        do throws(Coder.Error) {
            let quality = try Coder().parse(&input)
            guard input.isEmpty else { return nil }
            return quality
        } catch {
            return nil
        }
    }
}
