import Foundation

struct PayrollSettings {
    var saturdayAllowancePercentage: Decimal = 0.35
    var sundayAllowancePercentage: Decimal = 1
    var holidayAllowancePercentage: Decimal = 0.08
    var vacationPayoutPercentage: Decimal = 0.0919
    var minimumAttendanceHours: Decimal = 3
    var minimumAttendanceEnabled: Bool = true
    var includeAllowancesInHolidayPay: Bool = true
    var includeAllowancesInVacationPayout: Bool = true
    var vacationPayoutEnabled: Bool = true

    init(appSettings: AppSettings? = nil) {
        guard let appSettings else { return }
        saturdayAllowancePercentage = appSettings.saturdayAllowancePercentage
        sundayAllowancePercentage = appSettings.sundayAllowancePercentage
        holidayAllowancePercentage = appSettings.holidayAllowancePercentage
        vacationPayoutPercentage = appSettings.vacationPayoutPercentage
        minimumAttendanceHours = appSettings.minimumAttendanceHours
        minimumAttendanceEnabled = appSettings.minimumAttendanceEnabled
        includeAllowancesInHolidayPay = appSettings.includeAllowancesInHolidayPay
        includeAllowancesInVacationPayout = appSettings.includeAllowancesInVacationPayout
        vacationPayoutEnabled = appSettings.vacationPayoutEnabled
    }
}

struct SegmentInput {
    var type: ActivityType
    var start: Date
    var end: Date
    var isPaid: Bool
}

struct PayrollResult {
    var paidHours: Decimal
    var breakHours: Decimal
    var weekdayHours: Decimal
    var saturdayHours: Decimal
    var sundayOrHolidayHours: Decimal
    var basePaidHours: Decimal
    var basePay: Decimal
    var saturdayAllowance: Decimal
    var sundayAllowance: Decimal
    var holidayAllowance: Decimal
    var vacationPayout: Decimal
    var grossTotal: Decimal
    var activityHours: [ActivityType: Decimal]
    var hourlyRate: Decimal

    var totalAllowance: Decimal { saturdayAllowance + sundayAllowance }
}

enum PayrollValidationError: LocalizedError, Equatable {
    case missingEndTime
    case endBeforeStart
    case overlappingSegments
    case invalidPercentage
}

enum PayrollEngine {
    static let defaultRates: [(String, Decimal)] = [
        ("2025-07-01", 15.03),
        ("2026-01-01", 15.33),
        ("2026-07-01", 15.64),
        ("2027-01-01", 15.88),
        ("2027-07-01", 16.11)
    ]

    static func defaultHourlyRates(calendar: Calendar = .current) -> [HourlyRate] {
        defaultRates.map { HourlyRate(effectiveFrom: date($0.0, calendar: calendar), rate: $0.1) }
    }

    static func rate(for date: Date, rates: [HourlyRate]) -> Decimal {
        let sorted = rates.sorted { $0.effectiveFrom < $1.effectiveFrom }
        return sorted.last { rate in
            rate.effectiveFrom <= date && (rate.effectiveUntil == nil || date < rate.effectiveUntil!)
        }?.rate ?? sorted.last?.rate ?? 0
    }

    static func calculate(
        shiftDate: Date,
        segments: [SegmentInput],
        rates: [HourlyRate],
        settings: PayrollSettings,
        calendar: Calendar = .current,
        holidays: Set<Date> = []
    ) throws -> PayrollResult {
        try validate(segments: segments, settings: settings)
        let hourlyRate = rate(for: shiftDate, rates: rates)

        var paidHours: Decimal = 0
        var breakHours: Decimal = 0
        var weekdayHours: Decimal = 0
        var saturdayHours: Decimal = 0
        var sundayHours: Decimal = 0
        var activityHours: [ActivityType: Decimal] = [:]

        for segment in segments {
            let hours = decimalHours(from: segment.start, to: segment.end)
            activityHours[segment.type, default: 0] += hours
            if segment.type == .breakTime && !segment.isPaid {
                breakHours += hours
            }
            guard segment.isPaid else { continue }
            paidHours += hours
            for part in splitByCalendarDay(start: segment.start, end: segment.end, calendar: calendar) {
                let partHours = decimalHours(from: part.start, to: part.end)
                let day = calendar.startOfDay(for: part.start)
                let weekday = calendar.component(.weekday, from: part.start)
                if weekday == 1 || holidays.contains(day) {
                    sundayHours += partHours
                } else if weekday == 7 {
                    saturdayHours += partHours
                } else {
                    weekdayHours += partHours
                }
            }
        }

        let basePaidHours = settings.minimumAttendanceEnabled ? max(paidHours, settings.minimumAttendanceHours) : paidHours
        let basePay = roundMoney(basePaidHours * hourlyRate)
        let saturdayAllowance = roundMoney(saturdayHours * hourlyRate * settings.saturdayAllowancePercentage)
        let sundayAllowance = roundMoney(sundayHours * hourlyRate * settings.sundayAllowancePercentage)
        let allowanceTotal = saturdayAllowance + sundayAllowance
        let holidayBasis = settings.includeAllowancesInHolidayPay ? basePay + allowanceTotal : basePay
        let vacationBasis = settings.includeAllowancesInVacationPayout ? basePay + allowanceTotal : basePay
        let holidayAllowance = roundMoney(holidayBasis * settings.holidayAllowancePercentage)
        let vacationPayout = settings.vacationPayoutEnabled ? roundMoney(vacationBasis * settings.vacationPayoutPercentage) : 0
        let grossTotal = roundMoney(basePay + allowanceTotal + holidayAllowance + vacationPayout)

        return PayrollResult(
            paidHours: paidHours,
            breakHours: breakHours,
            weekdayHours: weekdayHours,
            saturdayHours: saturdayHours,
            sundayOrHolidayHours: sundayHours,
            basePaidHours: basePaidHours,
            basePay: basePay,
            saturdayAllowance: saturdayAllowance,
            sundayAllowance: sundayAllowance,
            holidayAllowance: holidayAllowance,
            vacationPayout: vacationPayout,
            grossTotal: grossTotal,
            activityHours: activityHours,
            hourlyRate: hourlyRate
        )
    }

    static func calculate(shift: Shift, rates: [HourlyRate], settings: PayrollSettings, calendar: Calendar = .current) throws -> PayrollResult {
        let inputs = try shift.orderedSegments.map { segment -> SegmentInput in
            guard let end = segment.endTime else { throw PayrollValidationError.missingEndTime }
            return SegmentInput(type: segment.type, start: segment.startTime, end: end, isPaid: segment.isPaid)
        }
        return try calculate(shiftDate: shift.date, segments: inputs, rates: rates, settings: settings, calendar: calendar)
    }

    static func employerDifferenceMinutes(shift: Shift, result: PayrollResult) -> Int? {
        guard let reported = shift.employerReportedMinutes else { return nil }
        let workedMinutes = NSDecimalNumber(decimal: result.paidHours * 60).rounding(accordingToBehavior: nil).intValue
        return Int(workedMinutes) - reported
    }

    static func missingGrossPay(differenceMinutes: Int, hourlyRate: Decimal) -> Decimal {
        guard differenceMinutes > 0 else { return 0 }
        return roundMoney((Decimal(differenceMinutes) / 60) * hourlyRate)
    }

    static func validate(segments: [SegmentInput], settings: PayrollSettings) throws {
        guard settings.saturdayAllowancePercentage >= 0,
              settings.sundayAllowancePercentage >= 0,
              settings.holidayAllowancePercentage >= 0,
              settings.vacationPayoutPercentage >= 0 else {
            throw PayrollValidationError.invalidPercentage
        }

        let sorted = segments.sorted { $0.start < $1.start }
        for segment in sorted where segment.end <= segment.start {
            throw PayrollValidationError.endBeforeStart
        }
        for pair in zip(sorted, sorted.dropFirst()) where pair.0.end > pair.1.start {
            throw PayrollValidationError.overlappingSegments
        }
    }

    static func decimalHours(from start: Date, to end: Date) -> Decimal {
        let seconds = Int(end.timeIntervalSince(start).rounded())
        return Decimal(seconds) / 3600
    }

    static func roundMoney(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .bankers)
        return output
    }

    static func date(_ value: String, calendar: Calendar = .current) -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
    }

    private static func splitByCalendarDay(start: Date, end: Date, calendar: Calendar) -> [(start: Date, end: Date)] {
        var parts: [(Date, Date)] = []
        var cursor = start
        while cursor < end {
            let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor))!
            let partEnd = min(nextMidnight, end)
            parts.append((cursor, partEnd))
            cursor = partEnd
        }
        return parts
    }
}
