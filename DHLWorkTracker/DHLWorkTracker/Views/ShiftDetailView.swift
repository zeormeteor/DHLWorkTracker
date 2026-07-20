import SwiftUI
import SwiftData

struct ShiftDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @Bindable var shift: Shift
    @State private var reportedHours = 0
    @State private var reportedMinutes = 0
    @State private var showDelete = false

    var body: some View {
        List {
            if let result {
                Section("Samenvatting") {
                    TotalRow(title: "Mijn uren", value: AppFormatters.hours(result.paidHours))
                    TotalRow(title: "DHL-uren", value: shift.employerReportedMinutes.map(AppFormatters.minutesToHours) ?? "Nog niet ingevuld")
                    TotalRow(title: "Mogelijk verschil", value: differenceText(result))
                    TotalRow(title: "Mogelijk ontbrekend bruto", value: missingPayText(result))
                    TotalRow(title: "Bruto totaal", value: AppFormatters.money(result.grossTotal))
                }
            }
            Section("DHL-opgave") {
                Stepper("Uren: \(reportedHours)", value: $reportedHours, in: 0...24)
                Stepper("Minuten: \(reportedMinutes)", value: $reportedMinutes, in: 0...59)
                Picker("Status", selection: Binding(get: { shift.employerStatementStatus }, set: { shift.employerStatementStatus = $0 })) {
                    ForEach(EmployerStatementStatus.allCases) { Text($0.dutchName).tag($0) }
                }
                Button("DHL-uren bewaren") {
                    shift.employerReportedMinutes = reportedHours * 60 + reportedMinutes
                    shift.updatedAt = .now
                    try? modelContext.save()
                }
            }
            Section("Activiteiten") {
                ForEach(shift.orderedSegments) { segment in
                    SegmentEditorRow(segment: segment)
                }
            }
            Section("Notitie") {
                TextField("Notitie", text: $shift.notes, axis: .vertical)
            }
            Section {
                Button("Shift verwijderen", role: .destructive) { showDelete = true }
            }
        }
        .navigationTitle("Shift")
        .onAppear {
            reportedHours = (shift.employerReportedMinutes ?? 0) / 60
            reportedMinutes = (shift.employerReportedMinutes ?? 0) % 60
        }
        .alert("Shift verwijderen?", isPresented: $showDelete) {
            Button("Verwijder", role: .destructive) {
                modelContext.delete(shift)
                try? modelContext.save()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Deze actie kan niet ongedaan worden gemaakt.")
        }
    }

    private var result: PayrollResult? {
        try? PayrollEngine.calculate(shift: shift, rates: rates, settings: PayrollSettings(appSettings: settingsRows.first))
    }

    private func differenceText(_ result: PayrollResult) -> String {
        guard let minutes = PayrollEngine.employerDifferenceMinutes(shift: shift, result: result) else { return "Nog controleren" }
        if minutes == 0 { return "Uren komen overeen" }
        return AppFormatters.minutesToHours(minutes)
    }

    private func missingPayText(_ result: PayrollResult) -> String {
        guard let minutes = PayrollEngine.employerDifferenceMinutes(shift: shift, result: result) else { return "Nog controleren" }
        return AppFormatters.money(PayrollEngine.missingGrossPay(differenceMinutes: minutes, hourlyRate: result.hourlyRate))
    }
}
