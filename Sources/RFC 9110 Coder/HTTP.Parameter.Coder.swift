import Pair
public import Byte
public import Cursor
public import Coder
public import RFC_9110
import Either
import Parser
import Product
import Serializer

extension RFC_9110.Parameter {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Parameter.Error

        public init() {}

        @Coder::Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Parameter, Buffer, Failure> {
            Coder::Coder(Input.self, Buffer.self) {
                RFC_9110.Token.Coder()
                Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: "="))
                Parser::OneOf.Two(
                    RFC_9110.Token.Coder().map(to: \.rawValue, from: { RFC_9110.Token(unchecked: $0) }),
                    RFC_9110.QuotedString.Coder()
                , rejectFirst: { if case .empty = $0 { return true }; return false }, rejectSecond: { if case .expectedOpenQuote = $0 { return true }; return false },
                    serializationRejectFirst: { failure in
                        switch failure {
                        case .empty, .invalidCharacter: true
                        }
                    })
            }
            .map(
                to: { output in RFC_9110.Parameter(name: output.first, value: output.second) },
                from: { .init($0.name, $0.value) }
            )
            .mapFailure { (failure) -> Failure in
                switch failure {
                case .left(.left(let error)): .expectedName(error)
                case .left(.right): .expectedEquals
                case .right(.first(let error)): .invalidTokenValue(error)
                case .right(.second(let error)): .invalidValue(error)
                case .right(.rejected(_, let error)): .invalidValue(error)
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedPrefix
        case expectedName(RFC_9110.Token.Error)
        case invalidTokenValue(RFC_9110.Token.Error)
        case expectedEquals
        case invalidValue(RFC_9110.QuotedString.Error)
    }
}

extension RFC_9110.Parameter {

    public struct Prefixed<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Parameter.Error

        public init() {}

        @Coder::Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Parameter, Buffer, Failure> {
            Coder::Coder(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                Coder::ConsumingLiteral<Input, Buffer>([Byte](utf8: ";"))
                RFC_9110.OWS.Coder(canonical: " ")
                RFC_9110.Parameter.Coder()
            }
            .mapFailure { (failure) -> Failure in
                switch failure {
                case .right(let error): error
                default: .expectedPrefix
                }
            }
        }
    }
}

extension [RFC_9110.Parameter] {

    static func sorted(_ parameters: [String: String]) -> Self {
        parameters.sorted { $0.key < $1.key }.map {
            RFC_9110.Parameter(name: RFC_9110.Token(unchecked: $0.key), value: $0.value)
        }
    }

    var dictionary: [String: String] {
        var result: [String: String] = [:]
        for parameter in self {
            result[parameter.name.rawValue] = parameter.value
        }
        return result
    }
}
