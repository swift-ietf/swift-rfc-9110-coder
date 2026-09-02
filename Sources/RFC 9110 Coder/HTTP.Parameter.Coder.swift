public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Parameter {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Parameter

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Parameter.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> RFC_9110.Parameter {
            let name: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                name = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                throw .expectedName(error)
            }

            let afterName = input.checkpoint
            guard let equals = input.next(), equals.bitPattern == 0x3D else {
                input.seek(to: afterName)
                throw .expectedEquals
            }

            if input.first?.bitPattern == 0x22 {
                do throws(RFC_9110.QuotedString.Coder.Error) {
                    let value = try RFC_9110.QuotedString.Coder().parse(&input)
                    return RFC_9110.Parameter(name: name, value: value)
                } catch {
                    throw .invalidQuotedString(error)
                }
            }

            do throws(RFC_9110.Token.Error) {
                let value = try RFC_9110.Token.Coder().parse(&input)
                return RFC_9110.Parameter(name: name, value: value.rawValue)
            } catch {
                throw .expectedValue
            }
        }

        public borrowing func serialize(_ output: RFC_9110.Parameter, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.name.rawValue.utf8.lazy.map(Byte.init(bitPattern:)))
            buffer.append(Byte(bitPattern: 0x3D))

            if !output.value.isEmpty, output.value.utf8.allSatisfy(RFC_9110.Token.isTchar) {
                buffer.append(contentsOf: output.value.utf8.lazy.map(Byte.init(bitPattern:)))
                return
            }

            do throws(RFC_9110.QuotedString.Coder.Error) {
                try RFC_9110.QuotedString.Coder().serialize(output.value, into: &buffer)
            } catch {
                throw .invalidQuotedString(error)
            }
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Parameter: Coder.Codable {}

extension RFC_9110.Parameter.Coder {

    public enum Error: Swift.Error, Equatable {
        case expectedName(RFC_9110.Token.Error)
        case expectedEquals
        case expectedValue
        case invalidQuotedString(RFC_9110.QuotedString.Coder.Error)
    }
}

enum Parameters {

    static func parse(_ input: inout Byte.Input) -> [RFC_9110.Parameter] {
        var parameters: [RFC_9110.Parameter] = []

        while true {
            let saved = input.checkpoint

            Whitespace.skip(&input)
            guard let semicolon = input.next(), semicolon.bitPattern == 0x3B else {
                input.seek(to: saved)
                break
            }
            Whitespace.skip(&input)

            do throws(RFC_9110.Parameter.Coder.Error) {
                parameters.append(try RFC_9110.Parameter.Coder().parse(&input))
            } catch {
                input.seek(to: saved)
                break
            }
        }

        return parameters
    }

    static func serialize(
        _ parameters: [RFC_9110.Parameter],
        into buffer: inout [Byte]
    ) throws(RFC_9110.Parameter.Coder.Error) {
        for parameter in parameters {
            buffer.append(Byte(bitPattern: 0x3B))
            buffer.append(Byte(bitPattern: 0x20))
            try RFC_9110.Parameter.Coder().serialize(parameter, into: &buffer)
        }
    }
}
