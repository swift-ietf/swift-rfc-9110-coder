import Pair
public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Either
import Parser
import Serializer

extension RFC_9110.Representation.Validator.EntityTag {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Representation.Validator.EntityTag.Error

        public init() {}

        @Coder::Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Representation.Validator.EntityTag, Buffer, Failure> {
            Coder::Coder(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                Parser::Optionally(Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: "W/")), rejected: { _ in true })
                RFC_9110.QuotedString.Coder()
            }
            .map(
                to: { output in RFC_9110.Representation.Validator.EntityTag(value: output.second, isWeak: output.first != nil) },
                from: { .init($0.isWeak ? Optional(()) : nil, $0.value) }
            )
            .mapFailure { (failure) -> Failure in
                switch failure {
                case .left: .expectedOpaqueTag(.expectedOpenQuote)
                case .right(let error): .expectedOpaqueTag(error)
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedOpaqueTag(RFC_9110.QuotedString.Error)
    }
}

extension RFC_9110.Representation.Validator.EntityTag {

    public static func parse(_ headerValue: String) -> Self? {
        var input = [Byte](utf8: headerValue)[...]
        do throws(Error) {
            return try coder.parse(&input)
        } catch {
            return nil
        }
    }
}

extension RFC_9110.Representation.Validator.EntityTag: @retroactive LosslessStringConvertible {

    public init?(_ description: String) {
        guard let parsed = Self.parse(description) else { return nil }
        self = parsed
    }
}

extension RFC_9110.Representation.Validator.EntityTag: @retroactive Encodable, @retroactive Decodable {

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
