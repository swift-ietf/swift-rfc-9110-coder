public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Message.Content.Negotiation.EncodingPreference {

    public struct Coder: Coding {

        public typealias Failure = RFC_9110.Message.Content.Negotiation.Weighted<RFC_9110.Token.Coder>.Error

        public init() {}

        public var body: some Coding<Byte.Input, RFC_9110.Message.Content.Negotiation.EncodingPreference, [Byte], Failure> {
            RFC_9110.Message.Content.Negotiation.Weighted(RFC_9110.Token.Coder()).map(
                to: {
                    RFC_9110.Message.Content.Negotiation.EncodingPreference(
                        encoding: RFC_9110.Message.Content.Encoding($0.value.rawValue),
                        quality: $0.quality
                    )
                },
                from: { (value: RFC_9110.Token(unchecked: $0.encoding.value), quality: $0.quality) }
            )
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Message.Content.Negotiation.EncodingPreference: Coder.Codable {}

extension RFC_9110.Message.Content.Negotiation.EncodingPreference {

    public static func parse(_ headerValue: String) -> [Self] {
        var input = Byte.Input(utf8: headerValue)
        let preferences = (try? RFC_9110.Field.Value.List(Coder()).parse(&input)) ?? []
        return preferences.sorted { $0.quality > $1.quality }
    }
}
