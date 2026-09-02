public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Entity.Tag {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Entity.Tag

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Entity.Tag.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> RFC_9110.Entity.Tag {
            Whitespace.skip(&input)

            var isWeak = false
            let beforeWeak = input.checkpoint
            if let w = input.next(), w.bitPattern == 0x57,
                let slash = input.next(), slash.bitPattern == 0x2F
            {
                isWeak = true
            } else {
                input.seek(to: beforeWeak)
            }

            do throws(RFC_9110.QuotedString.Coder.Error) {
                let value = try RFC_9110.QuotedString.Coder().parse(&input)
                return RFC_9110.Entity.Tag(value: value, isWeak: isWeak)
            } catch {
                throw .expectedOpaqueTag(error)
            }
        }

        public borrowing func serialize(_ output: RFC_9110.Entity.Tag, into buffer: inout [Byte]) throws(Failure) {
            if output.isWeak {
                buffer.append(Byte(bitPattern: 0x57))
                buffer.append(Byte(bitPattern: 0x2F))
            }
            do throws(RFC_9110.QuotedString.Coder.Error) {
                try RFC_9110.QuotedString.Coder().serialize(output.value, into: &buffer)
            } catch {
                throw .expectedOpaqueTag(error)
            }
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Entity.Tag: Coder.Codable {}

extension RFC_9110.Entity.Tag.Coder {

    public enum Error: Swift.Error, Equatable {
        case expectedOpaqueTag(RFC_9110.QuotedString.Coder.Error)
    }
}

extension RFC_9110.Entity.Tag {

    public static func parse(_ headerValue: String) -> Self? {
        var input = Byte.Input(utf8: headerValue)
        do throws(Coder.Error) {
            return try Coder().parse(&input)
        } catch {
            return nil
        }
    }
}

extension RFC_9110.Entity.Tag: @retroactive LosslessStringConvertible {

    public init?(_ description: String) {
        guard let parsed = Self.parse(description) else { return nil }
        self = parsed
    }
}

extension RFC_9110.Entity.Tag: @retroactive Encodable, @retroactive Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let entityTag = Self.parse(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid entity tag: \(string)"
            )
        }

        self = entityTag
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(headerValue)
    }
}
