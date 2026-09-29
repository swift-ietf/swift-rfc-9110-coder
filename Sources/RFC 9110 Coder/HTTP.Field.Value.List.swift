public import Byte
public import Coder
public import Cursor
public import Parser
public import RFC_9110
public import Serializer
import Either

extension RFC_9110.Field.Value {

    public struct List<Element: Coding>: Coding
    where
        Element.Input: Cursor.`Protocol`<Byte, Never>,
        Element.Buffer: RangeReplaceableCollection<Byte>,
        Element.Output: Copyable & Escapable
    {
        public typealias Input = Element.Input

        public typealias Buffer = Element.Buffer

        public typealias Output = [Element.Output]

        public typealias Failure = Error

        public let element: Element
        public let rejected: (Element.Failure) -> Bool

        public init(_ element: Element, rejected: @escaping (Element.Failure) -> Bool = { _ in false }) {
            self.element = element
            self.rejected = rejected
        }

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            RFC_9110.OWS.Coder<Input, Buffer>().parse(&input)

            let mark = input.checkpoint
            do throws(RFC_9110.Field.Value.Delimiter.Error) {
                try RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>().parse(&input)
            } catch {
                input.seek(to: mark)
            }

            let probe = input.checkpoint
            let hasElement = input.next() != nil
            input.seek(to: probe)
            if !hasElement { return [] }

            do throws(Parser::Many<Input, Element>.Separated<RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>>.Error) {
                return try Parser::Many.Separated(element, separator: RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>(), rejected: rejected, separatorRejected: { if case .expectedComma = $0 { return true }; return false })
                    .parse(&input)
            } catch {
                throw Self.error(error)
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            do throws(Parser::Many<Input, Element>.Separated<RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>>.Error) {
                try Parser::Many.Separated(element, separator: RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>(), rejected: rejected, separatorRejected: { if case .expectedComma = $0 { return true }; return false })
                    .serialize(output, into: &buffer)
            } catch {
                throw Self.error(error)
            }
        }

        static func error(
            _ failure: Parser::Many<Input, Element>.Separated<RFC_9110.Field.Value.Delimiter.Coder<Input, Buffer>>.Error
        ) -> Failure {
            switch failure {
            case .element(let error): .element(error)
            default: .delimiter
            }
        }
    }
}

extension RFC_9110.Field.Value.List {

    public enum Error: Swift.Error {
        case element(Element.Failure)
        case delimiter
    }
}

extension RFC_9110.Field.Value.List.Error: Equatable where Element.Failure: Equatable {}

extension RFC_9110.Field.Value {

    public enum Delimiter {}
}

extension RFC_9110.Field.Value.Delimiter {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = Void

        public typealias Failure = Error

        public let canonical: [Byte]

        public init(canonical: [Byte] = [Byte(bitPattern: 0x2C), Byte(bitPattern: 0x20)]) {
            self.canonical = canonical
        }

        public borrowing func parse(_ input: inout Input) throws(Failure) {
            var commas = 0
            while true {
                let mark = input.checkpoint
                _ = RFC_9110.Whitespace.skip(&input)
                guard let byte = input.next(), byte.bitPattern == 0x2C else {
                    input.seek(to: mark)
                    break
                }
                commas += 1
            }
            guard commas > 0 else { throw .expectedComma }
            _ = RFC_9110.Whitespace.skip(&input)
        }

        public borrowing func serialize(_ output: Void, into buffer: inout Buffer) throws(Failure) {
            buffer.append(contentsOf: canonical)
        }
    }

    public enum Error: Swift.Error, Equatable {
        case expectedComma
    }
}

extension RFC_9110.Field.Value {

    public static func tokens(in headerValue: String) -> [String] {
        var input = [Byte](utf8: headerValue)[...]
        let tokens = (try? List(RFC_9110.Token.coder).parse(&input)) ?? []
        return tokens.map(\.rawValue)
    }

    public static func directives(in headerValue: String) -> [(name: String, value: String?)] {
        var input = [Byte](utf8: headerValue)[...]
        return (try? List(RFC_9110.Field.Value.Directive.Coder<ArraySlice<Byte>, [Byte]>()).parse(&input)) ?? []
    }
}

extension RFC_9110.Field.Value {

    enum Directive {}
}

extension RFC_9110.Field.Value.Directive {

    struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        typealias Output = (name: String, value: String?)

        typealias Failure = RFC_9110.Token.Error

        borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let name = try RFC_9110.Token.Coder<Input, Buffer>().parse(&input)

            let mark = input.checkpoint
            RFC_9110.OWS.Coder<Input, Buffer>().parse(&input)
            guard let equals = input.next(), equals.bitPattern == 0x3D else {
                input.seek(to: mark)
                return (name: name.rawValue, value: nil)
            }
            RFC_9110.OWS.Coder<Input, Buffer>().parse(&input)

            let beforeValue = input.checkpoint
            if let quoted = try? RFC_9110.QuotedString.Coder<Input, Buffer>().parse(&input) {
                return (name: name.rawValue, value: quoted)
            }
            input.seek(to: beforeValue)
            if let token = try? RFC_9110.Token.Coder<Input, Buffer>().parse(&input) {
                return (name: name.rawValue, value: token.rawValue)
            }
            input.seek(to: mark)
            return (name: name.rawValue, value: nil)
        }

        borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            try RFC_9110.Token.Coder<Input, Buffer>().serialize(RFC_9110.Token(unchecked: output.name), into: &buffer)
            guard let value = output.value else { return }
            buffer.append(Byte(bitPattern: 0x3D))
            do throws(RFC_9110.Token.Error) {
                try RFC_9110.Token.Coder<Input, Buffer>().serialize(RFC_9110.Token(unchecked: value), into: &buffer)
            } catch {
                try? RFC_9110.QuotedString.Coder<Input, Buffer>().serialize(value, into: &buffer)
            }
        }
    }
}
