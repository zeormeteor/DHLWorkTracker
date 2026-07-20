import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    @Query(sort: \Shift.startTime) private var shifts: [Shift]
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @State private var filter: HistoryFilter = .thisMonth

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Periode", selection: $filter) {
                        Text("Deze week").tag(HistoryFilter.thisWeek)
                        Text("Deze maand").tag(HistoryFilter.thisMonth)
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        Metric("Gewerkt", AppFormatters.hours(totals.paidHours))
                        Metric("DHL-uren", AppFormatters.minutesToHours(totalReportedMinutes))
                        Metric("Mogelijk verschil", AppFormatters.minutesToHours(missingMinutes))
                        Metric("Weekdag", AppFormatters.hours(totals.weekdayHours))
                        Metric("Zaterdag", AppFormatters.hours(totals.saturdayHours))
                        Metric("Zondag", AppFormatters.hours(totals.sundayOrHolidayHours))
                        Metric("Basisloon", AppFormatters.money(totals.basePay))
                        Metric("Toeslagen", AppFormatters.money(totals.totalAllowance))
                        Metric("Vakantiegeld", AppFormatters.money(totals.holidayAllowance))
                        Metric("Vakantiedagen", AppFormatters.money(totals.vacationPayout))
                        Metric("Bruto totaal", AppFormatters.money(totals.grossTotal))
                    }

                    Chart(chartRows) { row in
                        BarMark(x: .value("Datum", row.date, unit: .day), y: .value("Uren", row.myHours))
                            .foregroundStyle(.orange)
                        BarMark(x: .value("Datum", row.date, unit: .day), y: .value("DHL", row.reportedHours))
                            .foregroundStyle(.gray)
                    }
                    .frame(height: 220)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Overzicht")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var filteredShifts: [Shift] {
        let calendar = Calendar.current
        let interval = filter == .thisWeek ? calendar.dateInterval(of: .weekOfYear, for: .now) : calendar.dateInterval(of: .month, for: .now)
        return shifts.filter { shift in
            guard shift.endTime != nil, let interval else { return false }
            return interval.contains(shift.startTime)
        }
    }

    private var results: [(Shift, PayrollResult)] {
        filteredShifts.compactMap { shift in
            guard let result = try? PayrollEngine.calculate(shift: shift, rates: rates, settings: PayrollSettings(appSettings: settingsRows.first)) else { return nil }
            return (shift, result)
        }
    }

    private var totals: PayrollResult {
        results.reduce(PayrollResult(paidHours: 0, breakHours: 0, weekdayHours: 0, saturdayHours: 0, sundayOrHolidayHours: 0, basePaidHours: 0, basePay: 0, saturdayAllowance: 0, sundayAllowance: 0, holidayAllowance: 0, vacationPayout: 0, grossTotal: 0, activityHours: [:], hourlyRate: 0)) { partial, item in
            let result = item.1
            return PayrollResult(
                paidHours: partial.paidHours + result.paidHours,
                breakHours: partial.breakHours + result.breakHours,
                weekdayHours: partial.weekdayHours + result.weekdayHours,
                saturdayHours: partial.saturdayHours + result.saturdayHours,
                sundayOrHolidayHours: partial.sundayOrHolidayHours + result.sundayOrHolidayHours,
                basePaidHours: partial.basePaidHours + result.basePaidHours,
                basePay: partial.basePay + result.basePay,
                saturdayAllowance: partial.saturdayAllowance + result.saturdayAllowance,
                sundayAllowance: partial.sundayAllowance + result.sundayAllowance,
                holidayAllowance: partial.holidayAllowance + result.holidayAllowance,
                vacationPayout: partial.vacationPayout + result.vacationPayout,
                grossTotal: partial.grossTotal + result.grossTotal,
                activityHours: partial.activityHours,
                hourlyRate: result.hourlyRate
            )
        }
    }

    private var totalReportedMinutes: Int {
        filteredShifts.compactMap(\.employerReportedMinutes).reduce(0, +)
    }

    private var missingMinutes: Int {
        results.compactMap { PayrollEngine.employerDifferenceMinutes(shift: $0.0, result: $0.1) }.filter { $0 > 0 }.reduce(0, +)
    }

    private var chartRows: [DailyHoursRow] {
        results.map {
            DailyHoursRow(date: $0.0.date, myHours: Double(truncating: NSDecimalNumber(decimal: $0.1.paidHours)), reportedHours: Double($0.0.employerReportedMinutes ?? 0) / 60)
        }
    }
}

struct DailyHoursRow: Identifiable {
    let id = UUID()
    var date: Date
    var myHours: Double
    var reportedHours: Double
}
