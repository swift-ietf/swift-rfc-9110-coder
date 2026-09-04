public import Byte
import Byte_Standard_Library_Integration
public import Cursor_Standard_Library_Integration
public import Coder
public import Cursor
public import RFC_9110
import Cursor_Coder
import Either
import Cursor_Parser_Optionally
import Iterator_Coder
import Parser
import Parser_Error
import Serializer

extension RFC_9110.Representation.Validator.EntityTag {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Representation.Validator.EntityTag.Error

        public init() {}

        @Coder::Coder.Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Representation.Validator.EntityTag, Buffer, Failure> {
            Coder::Coder.Sequence(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                Parser.Optionally([Byte].Coder("W/"))
                RFC_9110.QuotedString.Coder()
            }
            .map(
                to: { output in RFC_9110.Representation.Validator.EntityTag(value: output.1, isWeak: output.0 != nil) },
                from: { ($0.isWeak ? Optional(()) : nil, $0.value) }
            )
            .error.map { (failure) -> Failure in .expectedOpaqueTag(failure.value) }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedOpaqueTag(RFC_9110.QuotedString.Error)
    }
}

extension RFC_9110.Representation.Validator.EntityTag: Coder.Codable {}

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
