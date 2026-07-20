import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var saturdayAllowancePercentage: Decimal
    var sundayAllowancePercentage: Decimal
    var holidayAllowancePercentage: Decimal
    var vacationPayoutPercentage: Decimal
    var minimumAttendanceHours: Decimal
    var minimumAttendanceEnabled: Bool
    var includeAllowancesInHolidayPay: Bool
    var includeAllowancesInVacationPayout: Bool
    var vacationPayoutEnabled: Bool
    var currencyCode: String

    init(
        id: UUID = UUID(),
        saturdayAllowancePercentage: Decimal = 0.35,
        sundayAllowancePercentage: Decimal = 1.00,
        holidayAllowancePercentage: Decimal = 0.08,
        vacationPayoutPercentage: Decimal = 0.0919,
        minimumAttendanceHours: Decimal = 3,
        minimumAttendanceEnabled: Bool = true,
        includeAllowancesInHolidayPay: Bool = true,
        includeAllowancesInVacationPayout: Bool = true,
        vacationPayoutEnabled: Bool = true,
        currencyCode: String = "EUR"
    ) {
        self.id = id
        self.saturdayAllowancePercentage = saturdayAllowancePercentage
        self.sundayAllowancePercentage = sundayAllowancePercentage
        self.holidayAllowancePercentage = holidayAllowancePercentage
        self.vacationPayoutPercentage = vacationPayoutPercentage
        self.minimumAttendanceHours = minimumAttendanceHours
        self.minimumAttendanceEnabled = minimumAttendanceEnabled
        self.includeAllowancesInHolidayPay = includeAllowancesInHolidayPay
        self.includeAllowancesInVacationPayout = includeAllowancesInVacationPayout
        self.vacationPayoutEnabled = vacationPayoutEnabled
        self.currencyCode = currencyCode
    }
}
