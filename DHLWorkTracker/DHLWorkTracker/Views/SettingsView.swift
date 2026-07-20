import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @Query(sort: \Shift.startTime) private var shifts: [Shift]
    @State private var showDeleteAll = false

    var body: some View {
        NavigationStack {
            List {
                if let settings = settingsRows.first {
                    SettingsNumbers(settings: settings)
                }
                Section("Uurtarieven") {
                    ForEach(rates) { rate in
                        HStack {
                            Text(AppFormatters.shortDate.string(from: rate.effectiveFrom))
                            Spacer()
                            TextField("Tarief", value: Binding(get: { rate.rate }, set: { rate.rate = $0 }), format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 90)
                        }
                    }
                }
                Section {
                    ShareLink("Export CSV", item: CSVExporter.export(shifts: shifts, rates: rates, settings: PayrollSettings(appSettings: settingsRows.first)))
                    Button("Voorbeelddata opnieuw toevoegen") {
                        SeedData.sampleShifts().forEach(modelContext.insert)
                        try? modelContext.save()
                    }
                    Button("Alle data verwijderen", role: .destructive) { showDeleteAll = true }
                }
                Section("Disclaimer") {
                    Text("Alle bedragen zijn schattingen. Je arbeidsovereenkomst, loonstrook, toepasselijke cao en definitieve salarisverwerking bepalen wat daadwerkelijk wordt betaald.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Instellingen")
            .alert("Alle data verwijderen?", isPresented: $showDeleteAll) {
                Button("Verwijder", role: .destructive) { deleteAll() }
                Button("Annuleer", role: .cancel) {}
            } message: {
                Text("Shifts, activiteiten, tarieven en instellingen worden lokaal verwijderd.")
            }
        }
    }

    private func deleteAll() {
        shifts.forEach(modelContext.delete)
        rates.forEach(modelContext.delete)
        settingsRows.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

struct SettingsNumbers: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section("Berekening") {
            DecimalField("Zaterdagpercentage", value: $settings.saturdayAllowancePercentage)
            DecimalField("Zondag/feestdagpercentage", value: $settings.sundayAllowancePercentage)
            DecimalField("Vakantiegeldpercentage", value: $settings.holidayAllowancePercentage)
            Toggle("Toeslagen tellen mee voor vakantiegeld", isOn: $settings.includeAllowancesInHolidayPay)
            Toggle("Vakantiedagen uitbetaling", isOn: $settings.vacationPayoutEnabled)
            DecimalField("Vakantiedagen percentage", value: $settings.vacationPayoutPercentage)
            Toggle("Toeslagen tellen mee voor vakantiedagen", isOn: $settings.includeAllowancesInVacationPayout)
            Toggle("Minimumopkomst toepassen", isOn: $settings.minimumAttendanceEnabled)
            DecimalField("Minimumopkomst uren", value: $settings.minimumAttendanceHours)
            TextField("Valuta", text: $settings.currencyCode)
        }
    }
}

struct DecimalField: View {
    var title: String
    @Binding var value: Decimal

    init(_ title: String, value: Binding<Decimal>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.decimalPad)
    }
}
