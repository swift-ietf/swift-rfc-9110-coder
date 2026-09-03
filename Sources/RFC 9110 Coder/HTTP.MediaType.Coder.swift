public import Byte
import Byte_Standard_Library_Integration
public import Cursor_Standard_Library_Integration
public import Coder
public import Cursor
public import RFC_9110
import Cursor_Coder
import Either
import Cursor_Parser_Many
import Iterator_Coder
import Parser
import Parser_Error
import Serializer

extension RFC_9110.MediaType {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.MediaType.Error

        public init() {}

        @Coder::Coder.Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.MediaType, Buffer, Failure> {
            Coder::Coder.Sequence(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                RFC_9110.Token.Coder()
                "/"
                RFC_9110.Token.Coder()
                Parser.Many(RFC_9110.Parameter.Prefixed())
            }
            .map(
                to: { output in
                    RFC_9110.MediaType(output.0.rawValue, output.1.rawValue, parameters: output.2.dictionary)
                },
                from: {
                    (
                        RFC_9110.Token(unchecked: $0.type),
                        RFC_9110.Token(unchecked: $0.subtype),
                        [RFC_9110.Parameter].sorted($0.parameters)
                    )
                }
            )
            .error.map { (failure) -> Failure in
                switch failure {
                case .left(.left(.left(let error))): .expectedType(error.value)
                case .left(.left(.right)): .expectedSlash
                case .left(.right(let error)): .expectedSubtype(error)
                case .right(.element(let error)): .invalidParameter(error)
                case .right: .invalidParameter(.expectedName(.empty))
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedType(RFC_9110.Token.Error)
        case expectedSlash
        case expectedSubtype(RFC_9110.Token.Error)
        case invalidParameter(RFC_9110.Parameter.Error)
    }
}

extension RFC_9110.MediaType: Coder.Codable {}

extension RFC_9110.MediaType {

    public static func parse(_ string: String) -> Self? {
        var input = [Byte](utf8: string)[...]
        do throws(Error) {
            return try coder.parse(&input)
        } catch {
            return nil
        }
    }

    public func matches(_ pattern: String) -> Bool {
        guard let pattern = Self.parse(pattern) else {
            return false
        }
        return matches(pattern)
    }
}

extension RFC_9110.MediaType: @retroactive LosslessStringConvertible {

    public init?(_ description: String) {
        guard let parsed = Self.parse(description) else { return nil }
        self = parsed
    }
}

extension RFC_9110.MediaType: @retroactive Encodable, @retroactive Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let mediaType = Self.parse(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid media type: \(string)"
            )
        }

        self = mediaType
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
