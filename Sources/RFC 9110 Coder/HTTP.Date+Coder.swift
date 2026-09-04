public import RFC_5322
public import RFC_9110
import Byte
import Byte_Standard_Library_Integration
import Coder
import RFC_5322_Coder

extension RFC_5322.DateTime {

    public init?(_ field: RFC_9110.Field) {
        self.init(field.value)
    }

    public init?(_ value: RFC_9110.Field.Value) {
        guard let parsed = parseHTTPDate(value.rawValue) else {
            return nil
        }
        self = parsed
    }
}

extension RFC_9110.Field {

    public init(dateTime: RFC_5322.DateTime, name: Name = .date) {
        self.init(
            name: name,
            value: .init(unchecked: imfFixdate(dateTime))
        )
    }
}

private func imfFixdate(_ dateTime: RFC_5322.DateTime) -> String {

    let components = dateTime.withTimezone(offsetSeconds: 0).components

    let dayName = RFC_5322.DateTime.dayNames[components.weekday]
    let monthName = RFC_5322.DateTime.monthNames[components.month - 1]

    let day = paddedDecimal(components.day, width: 2)
    let year = paddedDecimal(components.year, width: 4)
    let hour = paddedDecimal(components.hour, width: 2)
    let minute = paddedDecimal(components.minute, width: 2)
    let second = paddedDecimal(components.second, width: 2)

    return "\(dayName), \(day) \(monthName) \(year) \(hour):\(minute):\(second) GMT"
}

private func paddedDecimal(_ value: Int, width: Int) -> String {
    let digits = String(value)
    guard digits.count < width else { return digits }
    return String(repeating: "0", count: width - digits.count) + digits
}

private func parseHTTPDate(_ string: String) -> RFC_5322.DateTime? {
    if let comma = string.firstIndex(of: ",") {

        let fields = string[string.index(after: comma)...]
            .split(whereSeparator: isHTTPDateSpace)
            .map(String.init)

        if let first = fields.first, first.contains("-") {
            return parseRFC850Date(fields)
        }
        return parseIMFFixdate(fields)
    }

    let fields = string.split(whereSeparator: isHTTPDateSpace).map(String.init)
    return parseAsctimeDate(fields)
}

private func parseIMFFixdate(_ fields: [String]) -> RFC_5322.DateTime? {
    guard fields.count == 5, fields[4] == "GMT" else { return nil }
    guard
        let day = Int(fields[0]),
        let month = monthNumber(fields[1]),
        let year = Int(fields[2]), fields[2].count == 4,
        let time = parseTimeOfDay(fields[3])
    else { return nil }
    return gmtDateTime(year: year, month: month, day: day, time: time)
}

private func parseRFC850Date(_ fields: [String]) -> RFC_5322.DateTime? {
    guard fields.count == 3, fields[2] == "GMT" else { return nil }
    let date = fields[0].split(separator: "-", omittingEmptySubsequences: false).map(String.init)
    guard
        date.count == 3,
        let day = Int(date[0]),
        let month = monthNumber(date[1]),
        date[2].count == 2, let twoDigitYear = Int(date[2]),
        let time = parseTimeOfDay(fields[1])
    else { return nil }

    let year = twoDigitYear < 70 ? 2000 + twoDigitYear : 1900 + twoDigitYear
    return gmtDateTime(year: year, month: month, day: day, time: time)
}

private func parseAsctimeDate(_ fields: [String]) -> RFC_5322.DateTime? {
    guard fields.count == 5 else { return nil }
    guard
        let month = monthNumber(fields[1]),
        let day = Int(fields[2]),
        let time = parseTimeOfDay(fields[3]),
        let year = Int(fields[4]), fields[4].count == 4
    else { return nil }
    return gmtDateTime(year: year, month: month, day: day, time: time)
}

private func parseTimeOfDay(_ field: String) -> (hour: Int, minute: Int, second: Int)? {
    let parts = field.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2 || parts.count == 3 else { return nil }
    guard let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
    if parts.count == 3 {
        guard let second = Int(parts[2]) else { return nil }
        return (hour, minute, second)
    }
    return (hour, minute, 0)
}

private func monthNumber(_ name: String) -> Int? {
    RFC_5322.DateTime.monthNames.firstIndex(of: name).map { $0 + 1 }
}

private func gmtDateTime(
    year: Int,
    month: Int,
    day: Int,
    time: (hour: Int, minute: Int, second: Int)
) -> RFC_5322.DateTime? {

    try? RFC_5322.DateTime(
        year: year,
        month: month,
        day: day,
        hour: time.hour,
        minute: time.minute,
        second: time.second,
        timezoneOffsetSeconds: 0
    )
}

private func isHTTPDateSpace(_ character: Character) -> Bool {
    character == " " || character == "\t"
}

extension RFC_5322.DateTime {

    var text: String {
        var buffer: [Byte] = []
        try? RFC_5322.DateTime.coder.serialize(self, into: &buffer)
        return String(decoding: buffer, as: UTF8.self)
    }
}
