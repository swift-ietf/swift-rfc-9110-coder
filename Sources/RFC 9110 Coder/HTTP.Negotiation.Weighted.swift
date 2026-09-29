public import Byte
public import Coder
public import Cursor
public import Parser
public import RFC_9110
public import Serializer
import Either

extension RFC_9110.Negotiation {

    public struct Weighted<Value: Coding>: Coding
    where
        Value.Input: Cursor.`Protocol`<Byte, Never>,
        Value.Buffer: RangeReplaceableCollection<Byte>,
        Value.Output: Copyable & Escapable
    {
        public typealias Input = Value.Input

        public typealias Buffer = Value.Buffer

        public typealias Output = (
            value: Value.Output,
            quality: RFC_9110.Negotiation.QualityValue
        )

        public typealias Failure = Error

        public let value: Value

        public init(_ value: Value) {
            self.value = value
        }

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let parsed: Value.Output
            do throws(Value.Failure) {
                parsed = try value.parse(&input)
            } catch {
                throw .value(error)
            }

            let mark = input.checkpoint
            RFC_9110.OWS.Coder<Input, Buffer>().parse(&input)
            guard let semicolon = input.next(), semicolon.bitPattern == 0x3B else {
                input.seek(to: mark)
                return (value: parsed, quality: .default)
            }
            input.seek(to: mark)

            do throws(RFC_9110.Negotiation.Weight.Error) {
                let quality = try RFC_9110.Negotiation.Weight.Coder<Input, Buffer>().parse(&input)
                return (value: parsed, quality: quality)
            } catch {
                input.seek(to: mark)
                throw .weight(error)
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            do throws(Value.Failure) {
                try value.serialize(output.value, into: &buffer)
            } catch {
                throw .value(error)
            }

            guard output.quality != .default else { return }
            do throws(RFC_9110.Negotiation.Weight.Error) {
                try RFC_9110.Negotiation.Weight.Coder<Input, Buffer>()
                    .serialize(output.quality, into: &buffer)
            } catch {
                throw .weight(error)
            }
        }
    }
}

extension RFC_9110.Negotiation.Weighted {

    public enum Error: Swift.Error {
        case value(Value.Failure)
        case weight(RFC_9110.Negotiation.Weight.Error)
    }
}

extension RFC_9110.Negotiation.Weighted.Error: Equatable where Value.Failure: Equatable {}

extension RFC_9110.Negotiation {

    public enum Weight {}
}

extension RFC_9110.Negotiation.Weight {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Negotiation.Weight.Error

        public init() {}

        @Coder::Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Negotiation.QualityValue, Buffer, Failure> {
            Coder::Coder(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: ";"))
                RFC_9110.OWS.Coder()
                Parser::OneOf.Two(Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: "q=")), Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: "Q=")), rejectFirst: { _ in true }, rejectSecond: { _ in true })
                RFC_9110.Negotiation.QualityValue.Coder()
            }
            .mapFailure { (failure) -> Failure in
                switch failure {
                case .right(let error): .quality(error)
                default: .expectedWeight
                }
            }
        }
    }

    public enum Error: Swift.Error, Equatable {
        case expectedWeight
        case quality(RFC_9110.Negotiation.QualityValue.Error)
    }
}
