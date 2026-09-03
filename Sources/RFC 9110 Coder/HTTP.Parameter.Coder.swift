public import Byte
import Byte_Standard_Library_Integration
public import Cursor_Standard_Library_Integration
public import Coder
public import Cursor
public import RFC_9110
import Cursor_Coder
import Either
import Cursor_Parser_OneOf
import Iterator_Coder
import Parser
import Parser_Error
import Product
import Serializer

extension RFC_9110.Parameter {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Parameter.Error

        public init() {}

        @Coder::Coder.Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Parameter, Buffer, Failure> {
            Coder::Coder.Sequence(Input.self, Buffer.self) {
                RFC_9110.Token.Coder()
                "="
                Parser.OneOf.Two(
                    RFC_9110.Token.Coder().map(to: \.rawValue, from: { RFC_9110.Token(unchecked: $0) }),
                    RFC_9110.QuotedString.Coder()
                )
            }
            .map(
                to: { output in RFC_9110.Parameter(name: output.0, value: output.1) },
                from: { ($0.name, $0.value) }
            )
            .error.map { (failure) -> Failure in
                switch failure {
                case .left(.left(let error)): .expectedName(error)
                case .left(.right): .expectedEquals
                case .right(let alternatives): .invalidValue(alternatives.values.1)
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedName(RFC_9110.Token.Error)
        case expectedEquals
        case invalidValue(RFC_9110.QuotedString.Error)
    }
}

extension RFC_9110.Parameter: Coder.Codable {}

extension RFC_9110.Parameter {

    public struct Prefixed<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Parameter.Error

        public init() {}

        @Coder::Coder.Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Parameter, Buffer, Failure> {
            Coder::Coder.Sequence(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                ";"
                RFC_9110.OWS.Coder(canonical: " ")
                RFC_9110.Parameter.Coder()
            }
            .error.map { (failure) -> Failure in
                switch failure {
                case .right(let error): error
                default: .expectedName(.empty)
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
