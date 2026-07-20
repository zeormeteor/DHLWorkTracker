import SwiftUI
import SwiftData

struct ShiftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @Bindable var shift: Shift
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if let result {
                    Section("Tijden") {
                        TotalRow(title: "Start", value: AppFormatters.time.string(from: shift.startTime))
                        TotalRow(title: "Einde", value: AppFormatters.time.string(from: shift.endTime ?? .now))
                        TotalRow(title: "Betaalde tijd", value: AppFormatters.hours(result.paidHours))
                        TotalRow(title: "Pauze", value: AppFormatters.hours(result.breakHours))
                    }
                    Section("Activiteiten") {
                        ForEach(shift.orderedSegments) { segment in
                            SegmentEditorRow(segment: segment)
                        }
                    }
                    Section("Schatting") {
                        TotalRow(title: "Basisloon", value: AppFormatters.money(result.basePay))
                        TotalRow(title: "Weekendtoeslag", value: AppFormatters.money(result.totalAllowance))
                        TotalRow(title: "Vakantiegeld", value: AppFormatters.money(result.holidayAllowance))
                        TotalRow(title: "Vakantiedagen uitbetaling", value: AppFormatters.money(result.vacationPayout))
                        TotalRow(title: "Bruto totaal", value: AppFormatters.money(result.grossTotal))
                    }
                } else {
                    Text("Controleer ontbrekende eindtijden of overlappende activiteiten.")
                }
            }
            .navigationTitle("Werkdag controleren")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") { onConfirm() }
                }
            }
        }
    }

    private var result: PayrollResult? {
        let reviewEnd = shift.endTime ?? .now
        let inputs = shift.orderedSegments.compactMap { segment -> SegmentInput? in
            let end = segment.endTime ?? reviewEnd
            guard end > segment.startTime else { return nil }
            return SegmentInput(type: segment.type, start: segment.startTime, end: end, isPaid: segment.isPaid)
        }
        return try? PayrollEngine.calculate(shiftDate: shift.date, segments: inputs, rates: rates, settings: PayrollSettings(appSettings: settingsRows.first))
    }
}

struct SegmentEditorRow: View {
    @Bindable var segment: WorkSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Activiteit", selection: Binding(get: { segment.type }, set: { segment.type = $0 })) {
                ForEach(ActivityType.allCases) { Text($0.dutchName).tag($0) }
            }
            DatePicker("Start", selection: $segment.startTime, displayedComponents: .hourAndMinute)
            DatePicker("Einde", selection: Binding(get: { segment.endTime ?? .now }, set: { segment.endTime = $0 }), displayedComponents: .hourAndMinute)
            Toggle("Betaald", isOn: $segment.isPaid)
        }
    }
}

struct EditStartTimeView: View {
    @Environment(\.dismiss) private var dismiss
    var shift: Shift
    @State private var date: Date
    var onSave: (Date) -> Void

    init(shift: Shift, onSave: @escaping (Date) -> Void) {
        self.shift = shift
        self._date = State(initialValue: shift.startTime)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Starttijd", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Starttijd")
            .toolbar {
                Button("Bewaar") {
                    onSave(date)
                    dismiss()
                }
            }
        }
    }
}

struct ForgottenActivityView: View {
    @Environment(\.dismiss) private var dismiss
    var shift: Shift
    @State private var type: ActivityType = .other
    @State private var start: Date
    @State private var end: Date
    var onSave: (ActivityType, Date, Date) -> Void

    init(shift: Shift, onSave: @escaping (ActivityType, Date, Date) -> Void) {
        self.shift = shift
        self._start = State(initialValue: shift.startTime)
        self._end = State(initialValue: .now)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Activiteit", selection: $type) {
                    ForEach(ActivityType.allCases) { Text($0.dutchName).tag($0) }
                }
                DatePicker("Start", selection: $start, displayedComponents: [.date, .hourAndMinute])
                DatePicker("Einde", selection: $end, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Activiteit toevoegen")
            .toolbar {
                Button("Bewaar") {
                    onSave(type, start, end)
                    dismiss()
                }
            }
        }
    }
}
