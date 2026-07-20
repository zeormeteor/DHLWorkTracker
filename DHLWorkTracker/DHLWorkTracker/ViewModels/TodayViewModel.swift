import Foundation
import Observation
import SwiftData

@Observable
final class TodayViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func startShift(at date: Date = .now) {
        let shift = Shift(date: Calendar.current.startOfDay(for: date), startTime: date)
        context.insert(shift)
        startActivity(.loading, in: shift, at: date)
    }

    func startActivity(_ type: ActivityType, in shift: Shift, at date: Date = .now) {
        closeCurrentActivity(in: shift, at: date)
        let segment = WorkSegment(shift: shift, type: type, startTime: date)
        shift.segments.append(segment)
        shift.updatedAt = date
        try? context.save()
    }

    func finishShift(_ shift: Shift, at date: Date = .now) {
        closeCurrentActivity(in: shift, at: date)
        shift.endTime = date
        shift.updatedAt = date
        try? context.save()
    }

    func editStartTime(_ shift: Shift, to date: Date) {
        shift.startTime = date
        shift.date = Calendar.current.startOfDay(for: date)
        if let first = shift.orderedSegments.first {
            first.startTime = date
        }
        shift.updatedAt = .now
        try? context.save()
    }

    func addForgottenActivity(_ type: ActivityType, start: Date, end: Date, to shift: Shift) {
        let segment = WorkSegment(shift: shift, type: type, startTime: start, endTime: end)
        shift.segments.append(segment)
        shift.updatedAt = .now
        try? context.save()
    }

    func undoLastActivityChange(in shift: Shift) {
        let ordered = shift.orderedSegments
        guard let last = ordered.last else { return }
        context.delete(last)
        if let previous = ordered.dropLast().last {
            previous.endTime = nil
        }
        shift.updatedAt = .now
        try? context.save()
    }

    private func closeCurrentActivity(in shift: Shift, at date: Date) {
        if let current = shift.orderedSegments.last(where: { $0.endTime == nil }) {
            current.endTime = date
        }
    }
}
