public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
import Parser
import Serializer

extension RFC_9110.Message.Content.Negotiation.MediaTypePreference {

    public struct Coder: Coding {

        public typealias Input = Byte.Input

        public typealias Output = RFC_9110.Message.Content.Negotiation.MediaTypePreference

        public typealias Buffer = [Byte]

        public typealias Failure = RFC_9110.Message.Content.Negotiation.MediaTypePreference.Coder.Error

        public init() {}

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> Output {
            var mediaType: RFC_9110.MediaType
            do throws(RFC_9110.MediaType.Coder.Error) {
                mediaType = try RFC_9110.MediaType.Coder().parse(&input)
            } catch {
                throw .mediaType(error)
            }

            var quality = RFC_9110.Message.Content.Negotiation.QualityValue.default
            if let weight = mediaType.parameters.removeValue(forKey: "q") {
                guard let parsed = RFC_9110.Message.Content.Negotiation.QualityValue.parse(weight) else {
                    throw .weight(.invalidQValue)
                }
                quality = parsed
            }

            return Output(mediaType: mediaType, quality: quality)
        }

        public borrowing func serialize(_ output: Output, into buffer: inout [Byte]) throws(Failure) {
            do throws(RFC_9110.MediaType.Coder.Error) {
                try RFC_9110.MediaType.Coder().serialize(output.mediaType, into: &buffer)
            } catch {
                throw .mediaType(error)
            }

            guard output.quality != .default else { return }
            buffer.append(contentsOf: ";q=".utf8.lazy.map(Byte.init(bitPattern:)))
            do throws(RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error) {
                try RFC_9110.Message.Content.Negotiation.QualityValue.Coder()
                    .serialize(output.quality, into: &buffer)
            } catch {
                throw .weight(error)
            }
        }
    }

    public static var coder: Coder { .init() }
}

extension RFC_9110.Message.Content.Negotiation.MediaTypePreference: Coder.Codable {}

extension RFC_9110.Message.Content.Negotiation.MediaTypePreference.Coder {

    public enum Error: Swift.Error, Equatable {
        case mediaType(RFC_9110.MediaType.Coder.Error)
        case weight(RFC_9110.Message.Content.Negotiation.QualityValue.Coder.Error)
    }
}

extension RFC_9110.Message.Content.Negotiation.MediaTypePreference {

    public static func parse(_ headerValue: String) -> [Self] {
        var input = Byte.Input(utf8: headerValue)
        let preferences = (try? RFC_9110.Field.Value.List(Coder()).parse(&input)) ?? []

        return preferences.sorted { lhs, rhs in
            if lhs.quality != rhs.quality {
                return lhs.quality > rhs.quality
            }
            if lhs.mediaType.type == "*" && rhs.mediaType.type != "*" { return false }
            if lhs.mediaType.type != "*" && rhs.mediaType.type == "*" { return true }
            if lhs.mediaType.subtype == "*" && rhs.mediaType.subtype != "*" { return false }
            if lhs.mediaType.subtype != "*" && rhs.mediaType.subtype == "*" { return true }
            return false
        }
    }
}
