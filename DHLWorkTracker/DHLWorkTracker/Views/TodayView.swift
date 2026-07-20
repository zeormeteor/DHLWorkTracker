import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.startTime, order: .reverse) private var shifts: [Shift]
    @Query(sort: \HourlyRate.effectiveFrom) private var rates: [HourlyRate]
    @Query private var settingsRows: [AppSettings]
    @State private var showingReview = false
    @State private var showingEditStart = false
    @State private var showingForgotten = false

    private var viewModel: TodayViewModel { TodayViewModel(context: modelContext) }
    private var activeShift: Shift? { shifts.first { $0.endTime == nil } }
    private var settings: PayrollSettings { PayrollSettings(appSettings: settingsRows.first) }

    var body: some View {
        NavigationStack {
            Group {
                if let shift = activeShift {
                    activeShiftView(shift)
                } else {
                    startView
                }
            }
            .navigationTitle("Vandaag")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var startView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(AppFormatters.date.string(from: .now))
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Geschat tarief vandaag")
                    .foregroundStyle(.secondary)
                Text(AppFormatters.money(PayrollEngine.rate(for: .now, rates: rates)))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
            }

            Button {
                viewModel.startShift()
            } label: {
                Label("Werkdag starten", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            DatePicker("Geplande start", selection: .constant(.now), displayedComponents: .hourAndMinute)
                .disabled(true)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
    }

    private func activeShiftView(_ shift: Shift) -> some View {
        let current = shift.orderedSegments.last { $0.endTime == nil }
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelineView(.periodic(from: .now, by: 30)) { timeline in
                    liveSummary(shift: shift, now: timeline.date)
                }

                Text("Nu: \(current?.type.dutchName ?? "Geen activiteit")")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ActivityType.allCases) { type in
                        Button {
                            viewModel.startActivity(type, in: shift)
                        } label: {
                            Text(type.dutchName)
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 54)
                        }
                        .buttonStyle(.bordered)
                        .tint(type == current?.type ? .orange : .primary)
                    }
                }

                Button(role: .destructive) {
                    showingReview = true
                } label: {
                    Label("Werkdag afronden", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Button("Ongedaan maken") { viewModel.undoLastActivityChange(in: shift) }
                    Spacer()
                    Button("Starttijd") { showingEditStart = true }
                    Spacer()
                    Button("Vergeten activiteit") { showingForgotten = true }
                }
                .font(.subheadline)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingReview) {
            ShiftReviewView(shift: shift) {
                viewModel.finishShift(shift)
                showingReview = false
            }
        }
        .sheet(isPresented: $showingEditStart) {
            EditStartTimeView(shift: shift) { date in
                viewModel.editStartTime(shift, to: date)
            }
        }
        .sheet(isPresented: $showingForgotten) {
            ForgottenActivityView(shift: shift) { type, start, end in
                viewModel.addForgottenActivity(type, start: start, end: end, to: shift)
            }
        }
    }

    private func liveSummary(shift: Shift, now: Date) -> some View {
        let inputs = shift.orderedSegments.compactMap { segment -> SegmentInput? in
            let end = segment.endTime ?? now
            guard end > segment.startTime else { return nil }
            return SegmentInput(type: segment.type, start: segment.startTime, end: end, isPaid: segment.isPaid)
        }
        let result = try? PayrollEngine.calculate(shiftDate: shift.date, segments: inputs, rates: rates, settings: settings)
        return VStack(alignment: .leading, spacing: 10) {
            Text(AppFormatters.hours(PayrollEngine.decimalHours(from: shift.startTime, to: now)))
                .font(.system(size: 56, weight: .bold, design: .rounded))
            HStack {
                Metric("Betaald", AppFormatters.hours(result?.paidHours ?? 0))
                Metric("Pauze", AppFormatters.hours(result?.breakHours ?? 0))
                Metric("Bruto", AppFormatters.money(result?.grossTotal ?? 0))
            }
        }
    }
}
