public import RFC_9110

extension RFC_9110.Representation.Encoding {

    public static func parse(_ headerValue: String) -> [Self] {
        RFC_9110.Field.Value.tokens(in: headerValue).map { Self($0) }
    }
}

extension RFC_9110.Representation.Language {

    public static func parse(_ headerValue: String) -> [Self] {
        RFC_9110.Field.Value.tokens(in: headerValue).map { Self($0) }
    }
}
