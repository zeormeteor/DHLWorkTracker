import XCTest
@testable import DHLWorkTracker

final class PayrollEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var rates: [HourlyRate]!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        rates = PayrollEngine.defaultHourlyRates(calendar: calendar)
    }

    func testWeekdayShift() throws {
        let result = try calculate("2026-07-02", [(.loading, "09:00", "17:00", true)])
        XCTAssertEqual(result.weekdayHours, 8)
        XCTAssertEqual(result.basePay, 125.12)
    }

    func testSaturdayShiftExactValues() throws {
        let result = try calculate("2026-07-04", [(.route, "09:00", "17:00", true)])
        XCTAssertEqual(result.paidHours, 8)
        XCTAssertEqual(result.basePay, 125.12)
        XCTAssertEqual(result.saturdayAllowance, 43.79)
    }

    func testSundayShift() throws {
        let result = try calculate("2026-07-05", [(.route, "09:00", "17:00", true)])
        XCTAssertEqual(result.sundayOrHolidayHours, 8)
        XCTAssertEqual(result.sundayAllowance, 125.12)
    }

    func testShiftCrossingMidnight() throws {
        let result = try calculate("2026-07-03", [(.driving, "22:00", "26:00", true)])
        XCTAssertEqual(result.weekdayHours, 2)
        XCTAssertEqual(result.saturdayHours, 2)
    }

    func testRateChangeOnFirstJuly2026() throws {
        let before = PayrollEngine.rate(for: date("2026-06-30", "12:00"), rates: rates)
        let after = PayrollEngine.rate(for: date("2026-07-01", "12:00"), rates: rates)
        XCTAssertEqual(before, 15.33)
        XCTAssertEqual(after, 15.64)
    }

    func testThreeHourMinimumAttendance() throws {
        let result = try calculate("2026-07-02", [(.route, "09:00", "10:00", true)])
        XCTAssertEqual(result.paidHours, 1)
        XCTAssertEqual(result.basePaidHours, 3)
        XCTAssertEqual(result.basePay, 46.92)
    }

    func testPaidAndUnpaidBreaks() throws {
        let result = try calculate("2026-07-02", [
            (.route, "09:00", "12:00", true),
            (.breakTime, "12:00", "12:30", false),
            (.breakTime, "12:30", "13:00", true),
            (.route, "13:00", "17:00", true)
        ])
        XCTAssertEqual(result.breakHours, 0.5)
        XCTAssertEqual(result.paidHours, 7.5)
    }

    func testHolidayAllowance() throws {
        let result = try calculate("2026-07-02", [(.route, "09:00", "17:00", true)])
        XCTAssertEqual(result.holidayAllowance, 10.01)
    }

    func testVacationPayout() throws {
        let result = try calculate("2026-07-02", [(.route, "09:00", "17:00", true)])
        XCTAssertEqual(result.vacationPayout, 11.50)
    }

    func testEmployerReportedDifference() throws {
        let shift = Shift(date: date("2026-07-02", "00:00"), startTime: date("2026-07-02", "09:00"), endTime: date("2026-07-02", "19:30"), employerReportedMinutes: 485)
        shift.segments = [WorkSegment(shift: shift, type: .route, startTime: date("2026-07-02", "09:00"), endTime: date("2026-07-02", "19:30"))]
        let result = try PayrollEngine.calculate(shift: shift, rates: rates, settings: PayrollSettings(), calendar: calendar)
        XCTAssertEqual(PayrollEngine.employerDifferenceMinutes(shift: shift, result: result), 145)
        XCTAssertEqual(PayrollEngine.missingGrossPay(differenceMinutes: 145, hourlyRate: result.hourlyRate), 37.80)
    }

    func testCurrencyRoundingUsingDecimal() {
        XCTAssertEqual(PayrollEngine.roundMoney(Decimal(string: "43.792")!), 43.79)
    }

    func testOverlappingSegmentsValidation() {
        XCTAssertThrowsError(try PayrollEngine.calculate(
            shiftDate: date("2026-07-02", "00:00"),
            segments: [
                SegmentInput(type: .route, start: date("2026-07-02", "09:00"), end: date("2026-07-02", "12:00"), isPaid: true),
                SegmentInput(type: .driving, start: date("2026-07-02", "11:00"), end: date("2026-07-02", "13:00"), isPaid: true)
            ],
            rates: rates,
            settings: PayrollSettings(),
            calendar: calendar
        )) { error in
            XCTAssertEqual(error as? PayrollValidationError, .overlappingSegments)
        }
    }

    func testFortyTwoHoursExactSummary() throws {
        let result = try calculate("2026-07-02", [
            (.route, "00:00", "24:00", true),
            (.route, "24:00", "34:00", true),
            (.route, "48:00", "56:00", true)
        ])
        XCTAssertEqual(result.paidHours, 42)
        XCTAssertEqual(result.weekdayHours, 34)
        XCTAssertEqual(result.saturdayHours, 8)
        XCTAssertEqual(result.basePay, 656.88)
        XCTAssertEqual(result.saturdayAllowance, 43.79)
        XCTAssertEqual(result.basePay + result.saturdayAllowance, 700.67)
    }

    private func calculate(_ day: String, _ rows: [(ActivityType, String, String, Bool)]) throws -> PayrollResult {
        try PayrollEngine.calculate(
            shiftDate: date(day, "00:00"),
            segments: rows.map { SegmentInput(type: $0.0, start: date(day, $0.1), end: date(day, $0.2), isPaid: $0.3) },
            rates: rates,
            settings: PayrollSettings(),
            calendar: calendar
        )
    }

    private func date(_ day: String, _ hourMinute: String) -> Date {
        let dayParts = day.split(separator: "-").compactMap { Int($0) }
        let timeParts = hourMinute.split(separator: ":").compactMap { Int($0) }
        let addedDays = timeParts[0] / 24
        let hour = timeParts[0] % 24
        let base = calendar.date(from: DateComponents(year: dayParts[0], month: dayParts[1], day: dayParts[2], hour: hour, minute: timeParts[1]))!
        return calendar.date(byAdding: .day, value: addedDays, to: base)!
    }
}
