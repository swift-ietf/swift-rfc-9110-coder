import Byte
import Byte_Standard_Library_Integration
import Cursor_Standard_Library_Integration
import Coder
import Iterator_Coder
import Parser
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
        var input = [Byte](utf8: headerValue)[...]
        let wildcard = Coder.Sequence(ArraySlice<Byte>.self, [Byte].self) {
            RFC_9110.OWS.Coder()
            "*"
            RFC_9110.OWS.Coder()
        }
        if (try? wildcard.parse(&input)) != nil, input.isEmpty {
            return [wildcardTag]
        }

        input = [Byte](utf8: headerValue)[...]
        let etags = (try? RFC_9110.Field.Value.List(RFC_9110.Entity.Tag.coder).parse(&input)) ?? []
        return etags.isEmpty ? nil : etags
    }
}
