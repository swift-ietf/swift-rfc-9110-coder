public import Byte
import Byte_Standard_Library_Integration
public import Cursor_Standard_Library_Integration
public import Coder
public import Cursor
public import RFC_9110
import Cursor_Coder
import Either
import Cursor_Parser_Many
import Parser
import Parser_Error
import Serializer

extension RFC_9110.Authentication.Challenge {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Failure = RFC_9110.Authentication.Challenge.Error

        public init() {}

        @Coder::Coder.Builder<Input, Buffer>
        public var body: some Coding<Input, RFC_9110.Authentication.Challenge, Buffer, Failure> {
            Coder::Coder.Sequence(Input.self, Buffer.self) {
                RFC_9110.OWS.Coder()
                RFC_9110.Token.Coder()
                Parser.Many(
                    0...1,
                    Coder::Coder.Sequence(Input.self, Buffer.self) {
                        RFC_9110.RWS.Coder()
                        RFC_9110.Field.Value.List(RFC_9110.Parameter.Coder())
                    }
                )
            }
            .map(
                to: { output in
                    RFC_9110.Authentication.Challenge(
                        scheme: .init(output.0.rawValue),
                        parameters: (output.1.first ?? []).dictionary
                    )
                },
                from: { challenge in
                    (
                        RFC_9110.Token(unchecked: challenge.scheme.name),
                        challenge.parameters.isEmpty ? [] : [[RFC_9110.Parameter].sorted(challenge.parameters)]
                    )
                }
            )
            .error.map { (failure) -> Failure in
                switch failure {
                case .left(let error): .expectedScheme(error.value)
                case .right(.element(.right(.element(let error)))): .invalidParameter(error)
                case .right: .expectedParameters
                }
            }
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

    public enum Error: Swift.Error, Equatable {
        case expectedScheme(RFC_9110.Token.Error)
        case expectedParameters
        case invalidParameter(RFC_9110.Parameter.Error)
    }
}

extension RFC_9110.Authentication.Challenge: Coder.Codable {}

extension RFC_9110.Authentication.Challenge {

    public static func parse(_ headerValue: String) -> Self? {
        var input = [Byte](utf8: headerValue)[...]
        do throws(Error) {
            return try coder.parse(&input)
        } catch {
            return nil
        }
    }
}
