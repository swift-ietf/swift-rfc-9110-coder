public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.MediaType {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.MediaType

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.MediaType.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> RFC_9110.MediaType {
            Whitespace.skip(&input)

            let type: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                type = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                throw .expectedType
            }

            let afterType = input.checkpoint
            guard let slash = input.next(), slash.bitPattern == 0x2F else {
                input.seek(to: afterType)
                throw .expectedSlash
            }

            let subtype: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                subtype = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                throw .expectedSubtype
            }

            var parameters: [String: String] = [:]
            for parameter in Parameters.parse(&input) {
                parameters[parameter.name.rawValue.lowercased()] = parameter.value
            }

            return RFC_9110.MediaType(type.rawValue, subtype.rawValue, parameters: parameters)
        }

        public borrowing func serialize(_ output: RFC_9110.MediaType, into buffer: inout [Byte]) throws(Failure) {
            buffer.append(contentsOf: output.type.utf8.lazy.map(Byte.init(bitPattern:)))
            buffer.append(Byte(bitPattern: 0x2F))
            buffer.append(contentsOf: output.subtype.utf8.lazy.map(Byte.init(bitPattern:)))

            var parameters: [RFC_9110.Parameter] = []
            for (name, value) in output.parameters.sorted(by: { $0.key < $1.key }) {
                do throws(RFC_9110.Token.Error) {
                    parameters.append(RFC_9110.Parameter(name: try RFC_9110.Token(name), value: value))
                } catch {
                    throw .invalidParameter(.expectedName(error))
                }
            }

            do throws(RFC_9110.Parameter.Coder.Error) {
                try Parameters.serialize(parameters, into: &buffer)
            } catch {
                throw .invalidParameter(error)
            }
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.MediaType: Coder.Codable {}

extension RFC_9110.MediaType.Coder {

    public enum Error: Swift.Error, Equatable {
        case expectedType
        case expectedSlash
        case expectedSubtype
        case invalidParameter(RFC_9110.Parameter.Coder.Error)
    }
}

extension RFC_9110.MediaType {

    public static func parse(_ string: String) -> Self? {
        var input = Byte.Input(utf8: string)
        do throws(Coder.Error) {
            return try Coder().parse(&input)
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
