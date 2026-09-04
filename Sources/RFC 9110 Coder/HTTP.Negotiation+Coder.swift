public import RFC_9110

extension RFC_9110.Negotiation {

    public static func selectMediaType(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> RFC_9110.MediaType? {
        selectMediaType(from: available, preferences: MediaTypePreference.parse(acceptHeader))
    }

    public static func selectMediaTypes(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> [RFC_9110.MediaType] {
        selectMediaTypes(from: available, preferences: MediaTypePreference.parse(acceptHeader))
    }
}
