import Byte
import Byte_Parser
import RFC_5322
public import RFC_9110
import Standard_Library_Extensions

extension RFC_9110.Precondition {

    public static func parseIfMatch(_ headerValue: String) -> RFC_9110.Precondition? {
        guard let etags = entityTags(in: headerValue) else { return nil }
        return .ifMatch(etags)
    }

    public static func parseIfNoneMatch(_ headerValue: String) -> RFC_9110.Precondition? {
        guard let etags = entityTags(in: headerValue) else { return nil }
        return .ifNoneMatch(etags)
    }

    public static func parseIfModifiedSince(_ headerValue: String) -> RFC_9110.Precondition? {
        do throws(RFC_5322.DateTime.Error) {
            return .ifModifiedSince(try RFC_5322.DateTime(headerValue))
        } catch {
            return nil
        }
    }

    public static func parseIfUnmodifiedSince(_ headerValue: String) -> RFC_9110.Precondition? {
        do throws(RFC_5322.DateTime.Error) {
            return .ifUnmodifiedSince(try RFC_5322.DateTime(headerValue))
        } catch {
            return nil
        }
    }

    public static func parseIfRange(_ headerValue: String) -> RFC_9110.Precondition? {
        let trimmed = String(headerValue.trimming(where: { $0.isWhitespace }))

        if let etag = RFC_9110.Entity.Tag.parse(trimmed) {
            return .ifRange(.etag(etag))
        }

        do throws(RFC_5322.DateTime.Error) {
            return .ifRange(.date(try RFC_5322.DateTime(trimmed)))
        } catch {
            return nil
        }
    }

    private static func entityTags(in headerValue: String) -> [RFC_9110.Entity.Tag]? {
        var input = Byte.Input(utf8: headerValue)
        Whitespace.skip(&input)

        if input.first?.bitPattern == 0x2A {
            let saved = input.checkpoint
            _ = input.next()
            Whitespace.skip(&input)
            if input.isEmpty {
                return [wildcardTag]
            }
            input.seek(to: saved)
        }

        let etags = (try? RFC_9110.Field.Value.List(RFC_9110.Entity.Tag.Coder()).parse(&input)) ?? []
        return etags.isEmpty ? nil : etags
    }
}
