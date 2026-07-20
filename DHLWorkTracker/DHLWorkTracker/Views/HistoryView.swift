import SwiftUI
import SwiftData

enum HistoryFilter: String, CaseIterable, Identifiable {
    case thisWeek = "Deze week"
    case previousWeek = "Vorige week"
    case thisMonth = "Deze maand"
    case custom = "Aangepast"

    var id: String { rawValue }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.startTime, order: .reverse) private var shifts: [Shift]
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @State private var filter: HistoryFilter = .thisMonth
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    @State private var customEnd = Date.now

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Periode", selection: $filter) {
                        ForEach(HistoryFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if filter == .custom {
                        DatePicker("Van", selection: $customStart, displayedComponents: .date)
                        DatePicker("Tot", selection: $customEnd, displayedComponents: .date)
                    }
                }
                ForEach(filteredShifts) { shift in
                    NavigationLink {
                        ShiftDetailView(shift: shift)
                    } label: {
                        ShiftRow(shift: shift, result: result(for: shift))
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Geschiedenis")
        }
    }

    private var filteredShifts: [Shift] {
        let calendar = Calendar.current
        let completed = shifts.filter { $0.endTime != nil }
        let interval: DateInterval? = {
            switch filter {
            case .thisWeek:
                return calendar.dateInterval(of: .weekOfYear, for: .now)
            case .previousWeek:
                guard let week = calendar.dateInterval(of: .weekOfYear, for: .now),
                      let start = calendar.date(byAdding: .weekOfYear, value: -1, to: week.start),
                      let end = calendar.date(byAdding: .weekOfYear, value: -1, to: week.end) else { return nil }
                return DateInterval(start: start, end: end)
            case .thisMonth:
                return calendar.dateInterval(of: .month, for: .now)
            case .custom:
                return DateInterval(start: calendar.startOfDay(for: customStart), end: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEnd)) ?? customEnd)
            }
        }()
        guard let interval else { return completed }
        return completed.filter { interval.contains($0.startTime) }
    }

    private func result(for shift: Shift) -> PayrollResult? {
        try? PayrollEngine.calculate(shift: shift, rates: rates, settings: PayrollSettings(appSettings: settingsRows.first))
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredShifts[index])
        }
        try? modelContext.save()
    }
}

struct ShiftRow: View {
    var shift: Shift
    var result: PayrollResult?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(AppFormatters.shortDate.string(from: shift.date))
                    .font(.headline)
                Text("\(AppFormatters.time.string(from: shift.startTime)) - \(shift.endTime.map(AppFormatters.time.string) ?? "--:--")")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(AppFormatters.money(result?.grossTotal ?? 0))
                    .fontWeight(.semibold)
                Text(AppFormatters.hours(result?.paidHours ?? 0))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var difference: Int? {
        guard let result else { return nil }
        return PayrollEngine.employerDifferenceMinutes(shift: shift, result: result)
    }

    private var statusIcon: String {
        guard let difference else { return "questionmark.circle" }
        return difference > 0 ? "exclamationmark.circle" : "checkmark.circle"
    }

    private var statusColor: Color {
        guard let difference else { return .secondary }
        return difference > 0 ? .orange : .green
    }
}
