import Foundation
import SwiftData

@Model
final class Shift {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var notes: String
    var employerReportedMinutes: Int?
    var employerStatementStatusRaw: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkSegment.shift)
    var segments: [WorkSegment]

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date? = nil,
        notes: String = "",
        employerReportedMinutes: Int? = nil,
        employerStatementStatus: EmployerStatementStatus = .notEntered,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        segments: [WorkSegment] = []
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.employerReportedMinutes = employerReportedMinutes
        self.employerStatementStatusRaw = employerStatementStatus.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.segments = segments
    }

    var employerStatementStatus: EmployerStatementStatus {
        get { EmployerStatementStatus(rawValue: employerStatementStatusRaw) ?? .notEntered }
        set { employerStatementStatusRaw = newValue.rawValue }
    }

    var orderedSegments: [WorkSegment] {
        segments.sorted { $0.startTime < $1.startTime }
    }
}
