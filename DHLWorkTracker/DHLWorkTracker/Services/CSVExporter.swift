import Foundation

enum CSVExporter {
    static func export(shifts: [Shift], rates: [HourlyRate], settings: PayrollSettings) -> String {
        let header = [
            "Date", "Start time", "End time", "Paid hours", "Break hours", "Loading hours", "Driving hours",
            "Route hours", "Pickup hours", "Waiting hours", "Scanning hours", "Weekday hours", "Saturday hours",
            "Sunday hours", "Base pay", "Allowance", "Holiday allowance", "Vacation payout", "Estimated gross total",
            "DHL-reported hours", "Difference", "Notes"
        ].joined(separator: ",")
        let rows = shifts.sorted { $0.startTime < $1.startTime }.compactMap { shift -> String? in
            guard let result = try? PayrollEngine.calculate(shift: shift, rates: rates, settings: settings) else { return nil }
            let difference = PayrollEngine.employerDifferenceMinutes(shift: shift, result: result)
            let values: [String] = [
                AppFormatters.shortDate.string(from: shift.date),
                AppFormatters.time.string(from: shift.startTime),
                shift.endTime.map(AppFormatters.time.string) ?? "",
                decimal(result.paidHours),
                decimal(result.breakHours),
                decimal(result.activityHours[.loading, default: 0]),
                decimal(result.activityHours[.driving, default: 0]),
                decimal(result.activityHours[.route, default: 0]),
                decimal(result.activityHours[.pickup, default: 0]),
                decimal(result.activityHours[.waiting, default: 0]),
                decimal(result.activityHours[.scanning, default: 0]),
                decimal(result.weekdayHours),
                decimal(result.saturdayHours),
                decimal(result.sundayOrHolidayHours),
                decimal(result.basePay),
                decimal(result.totalAllowance),
                decimal(result.holidayAllowance),
                decimal(result.vacationPayout),
                decimal(result.grossTotal),
                shift.employerReportedMinutes.map { AppFormatters.minutesToHours($0) } ?? "",
                difference.map { AppFormatters.minutesToHours($0) } ?? "",
                shift.notes
            ]
            return values.map(escape).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private static func decimal(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private static func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
