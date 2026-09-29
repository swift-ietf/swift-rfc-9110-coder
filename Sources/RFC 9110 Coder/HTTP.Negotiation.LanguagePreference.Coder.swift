public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Negotiation.LanguagePreference {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Negotiation.Weighted<RFC_9110.Token.Coder<Input, Buffer>>.Error

        public init() {}

        public var body: some Coding<Input, RFC_9110.Negotiation.LanguagePreference, Buffer, Failure> {
            RFC_9110.Negotiation.Weighted(RFC_9110.Token.Coder<Input, Buffer>())
                .map(
                    to: { RFC_9110.Negotiation.LanguagePreference(language: $0.value.rawValue, quality: $0.quality) },
                    from: { (value: RFC_9110.Token(unchecked: $0.language), quality: $0.quality) }
                )
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}


extension RFC_9110.Negotiation.LanguagePreference {

    public static func parse(_ headerValue: String) -> [Self] {
        var input = [Byte](utf8: headerValue)[...]
        let preferences = (try? RFC_9110.Field.Value.List(coder).parse(&input)) ?? []
        return preferences.sorted { lhs, rhs in
            if lhs.quality != rhs.quality {
                return lhs.quality > rhs.quality
            }
            return lhs.language.count > rhs.language.count
        }
    }
}
