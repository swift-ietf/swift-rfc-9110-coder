public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Authentication.Challenge {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Authentication.Challenge

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Authentication.Challenge.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> Output {
            Whitespace.skip(&input)

            let scheme: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                scheme = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                throw .expectedScheme(error)
            }

            Whitespace.skip(&input)
            guard !input.isEmpty else {
                return Output(scheme: .init(scheme.rawValue))
            }

            var parameters: [String: String] = [:]
            let parsed = (try? RFC_9110.Field.Value.List(RFC_9110.Parameter.Coder()).parse(&input)) ?? []
            for parameter in parsed {
                parameters[parameter.name.rawValue] = parameter.value
            }

            return Output(scheme: .init(scheme.rawValue), parameters: parameters)
        }

        public borrowing func serialize(_ output: Output, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.scheme.name.utf8.lazy.map(Byte.init(bitPattern:)))
            guard !output.parameters.isEmpty else { return }
            buffer.append(Byte(bitPattern: 0x20))

            var parameters: [RFC_9110.Parameter] = []
            for (name, value) in output.parameters.sorted(by: { $0.key < $1.key }) {
                do throws(RFC_9110.Token.Error) {
                    parameters.append(RFC_9110.Parameter(name: try RFC_9110.Token(name), value: value))
                } catch {
                    throw .invalidParameter(.expectedName(error))
                }
            }

            do throws(RFC_9110.Parameter.Coder.Error) {
                try RFC_9110.Field.Value.List(RFC_9110.Parameter.Coder()).serialize(parameters, into: &buffer)
            } catch {
                throw .invalidParameter(error)
            }
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Authentication.Challenge: Coder.Codable {}

extension RFC_9110.Authentication.Challenge.Coder {

    public enum Error: Swift.Error, Equatable {
        case expectedScheme(RFC_9110.Token.Error)
        case invalidParameter(RFC_9110.Parameter.Coder.Error)
    }
}

extension RFC_9110.Authentication.Challenge {

    public static func parse(_ headerValue: String) -> Self? {
        var input = Byte.Input(utf8: headerValue)
        do throws(Coder.Error) {
            return try Coder().parse(&input)
        } catch {
            return nil
        }
    }
}
