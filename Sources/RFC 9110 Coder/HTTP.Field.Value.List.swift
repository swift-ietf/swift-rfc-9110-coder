public import Byte
public import Byte_Parser
public import Coder
public import RFC_9110
public import Parser
public import Serializer

extension RFC_9110.Field.Value {

    public struct List<Element: Coding>: Coding
    where
        Element.Input == Byte.Input,
        Element.Buffer == [Byte],
        Element.Output: Copyable & Escapable
    {
        public typealias Input = Byte.Input

        public typealias Output = [Element.Output]

        public typealias Buffer = [Byte]

        public typealias Failure = Element.Failure

        public let element: Element

        public init(_ element: Element) {
            self.element = element
        }

        public borrowing func parse(_ input: inout Byte.Input) throws(Failure) -> [Element.Output] {
            var elements: [Element.Output] = []
            Whitespace.skip(&input)

            while !input.isEmpty {
                if input.first?.bitPattern == 0x2C {
                    _ = input.next()
                    Whitespace.skip(&input)
                    continue
                }

                let mark = input.checkpoint
                do throws(Element.Failure) {
                    elements.append(try element.parse(&input))
                } catch {
                    input.seek(to: mark)
                    break
                }

                guard Comma.consume(&input) else { break }
            }

            return elements
        }

        public borrowing func serialize(_ output: [Element.Output], into buffer: inout [Byte]) throws(Failure) {
            for (index, element) in output.enumerated() {
                if index > 0 {
                    buffer.append(Byte(bitPattern: 0x2C))
                    buffer.append(Byte(bitPattern: 0x20))
                }
                try self.element.serialize(element, into: &buffer)
            }
        }
    }
}

extension RFC_9110.Field.Value {

    public static func tokens(in headerValue: String) -> [String] {
        var input = Byte.Input(utf8: headerValue)
        let tokens = (try? List(RFC_9110.Token.Coder()).parse(&input)) ?? []
        return tokens.map(\.rawValue)
    }

    public static func directives(in headerValue: String) -> [(name: String, value: String?)] {
        var input = Byte.Input(utf8: headerValue)
        var directives: [(name: String, value: String?)] = []
        Whitespace.skip(&input)

        while !input.isEmpty {
            if input.first?.bitPattern == 0x2C {
                _ = input.next()
                Whitespace.skip(&input)
                continue
            }

            let name: RFC_9110.Token
            do throws(RFC_9110.Token.Error) {
                name = try RFC_9110.Token.Coder().parse(&input)
            } catch {
                break
            }

            var value: String?
            let afterName = input.checkpoint
            Whitespace.skip(&input)
            if let equals = input.next(), equals.bitPattern == 0x3D {
                Whitespace.skip(&input)
                let beforeValue = input.checkpoint
                if let quoted = try? RFC_9110.QuotedString.Coder().parse(&input) {
                    value = quoted
                } else {
                    input.seek(to: beforeValue)
                    if let token = try? RFC_9110.Token.Coder().parse(&input) {
                        value = token.rawValue
                    } else {
                        input.seek(to: beforeValue)
                    }
                }
            } else {
                input.seek(to: afterName)
            }

            directives.append((name: name.rawValue, value: value))
            guard Comma.consume(&input) else { break }
        }

        return directives
    }
}
