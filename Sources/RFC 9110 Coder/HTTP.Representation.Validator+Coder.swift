public import RFC_9110

extension RFC_9110.Representation.Validator: @retroactive CustomStringConvertible {

    public var description: String {
        switch self {
        case .entityTag(let entityTag):
            return entityTag.headerValue

        case .lastModified(let lastModified):
            return lastModified.text
        }
    }
}
