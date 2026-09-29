# swift-rfc-9110-coder

Wire coders for [swift-rfc-9110](https://github.com/swift-ietf/swift-rfc-9110): `RFC_9110.Token.Coder`, `RFC_9110.QuotedString.Coder`, `RFC_9110.Parameter.Coder`, `RFC_9110.MediaType.Coder`, `RFC_9110.Field.Value.List`, `RFC_9110.Field.Value.Delimiter.Coder`, `RFC_9110.OWS.Coder`, `RFC_9110.RWS.Coder`, `RFC_9110.Authentication.Challenge.Coder`, `RFC_9110.Authentication.Credentials.Coder`, `RFC_9110.Representation.Validator.EntityTag.Coder`, `RFC_9110.Negotiation.Weighted`, `RFC_9110.Negotiation.Weight.Coder`, `RFC_9110.Negotiation.QualityValue.Coder` and the `CharsetPreference`, `EncodingPreference`, `LanguagePreference` and `MediaTypePreference` coders parse and serialize the HTTP Semantics text forms over any byte cursor, `Coder.Codable` gives the domain types `encoded()` and `init(decoding:)`, and the HTTP-date bridging for `RFC_5322.DateTime`, the `Precondition`, `Validator` and `Vary` text forms and the `LosslessStringConvertible` conformances live here so that the domain package stays a pure model.

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
