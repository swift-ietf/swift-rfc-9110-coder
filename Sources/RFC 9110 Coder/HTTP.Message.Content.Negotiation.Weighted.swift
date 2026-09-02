public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
public import Parser
public import Serializer

extension RFC_9110.Message.Content.Negotiation {

    public struct Weighted<Value: Coding>: Coding
    where
        Value.Input == Byte.Input,
        Value.Buffer == [Byte],
        Value.Output: Copyable & Escapable
    {
        public typealias Input = Byte.Input

        public typealias Output = (
            value: Value.Output,
            quality: RFC_9110.Message.Content.Negotiation.QualityValue
        )

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Message.Content.Negotiation.Weighted<Value>.Error

        public let value: Value

        public init(_ value: Value) {
            self.value = value
        }

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> Output {
            let parsed: Value.Output
            do throws(Value.Failure) {
                parsed = try value.parse(&input)
            } catch {
                throw .value(error)
            }

            let beforeWeight = input.checkpoint
            Whitespace.skip(&input)
            guard let semicolon = input.next(), semicolon.bitPattern == 0x3B else {
                input.seek(to: beforeWeight)
                return (value: parsed, quality: .default)
            }
            Whitespace.skip(&input)

            guard let q = input.next(), q.bitPattern == 0x71 || q.bitPattern == 0x51,
                let equals = input.next(), equals.bitPattern == 0x3D
            else {
                throw .weight(.invalidQValue)
            }

            let quality: RFC_9110.Message.Content.Negotiation.QualityValue
            do throws(RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error) {
                quality = try RFC_9110.Message.Content.Negotiation.QualityValue.Coder().parse(&input)
            } catch {
                throw .weight(error)
            }
            Whitespace.skip(&input)
            return (value: parsed, quality: quality)
        }

        public borrowing func serialize(_ output: Output, into buffer: inout [Byte]) throws(Failure) {
            do throws(Value.Failure) {
                try value.serialize(output.value, into: &buffer)
            } catch {
                throw .value(error)
            }

            guard output.quality != .default else { return }
            buffer.append(contentsOf: ";q=".utf8.lazy.map(Byte.init(bitPattern:)))
            do throws(RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error) {
                try RFC_9110.Message.Content.Negotiation.QualityValue.Coder()
                    .serialize(output.quality, into: &buffer)
            } catch {
                throw .weight(error)
            }
        }
    }
}

extension RFC_9110.Message.Content.Negotiation.Weighted {

    public enum Error: Swift.Error {
        case value(Value.Failure)
        case weight(RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error)
    }
}
