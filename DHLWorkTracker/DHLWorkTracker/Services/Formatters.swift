import Foundation

enum AppFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateStyle = .full
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateStyle = .medium
        return formatter
    }()

    static let money: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }()

    static func money(_ value: Decimal) -> String {
        money.string(from: NSDecimalNumber(decimal: value)) ?? "EUR \(value)"
    }

    static func hours(_ value: Decimal) -> String {
        let minutes = NSDecimalNumber(decimal: value * 60).rounding(accordingToBehavior: nil).intValue
        return minutesToHours(minutes)
    }

    static func minutesToHours(_ minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : ""
        let absolute = abs(minutes)
        return "\(sign)\(absolute / 60):\(String(format: "%02d", absolute % 60))"
    }
}
