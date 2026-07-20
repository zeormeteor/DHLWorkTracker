import Foundation
import SwiftData

@Model
final class WorkSegment {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var startTime: Date
    var endTime: Date?
    var isPaid: Bool
    var note: String
    var shift: Shift?

    init(
        id: UUID = UUID(),
        shift: Shift? = nil,
        type: ActivityType,
        startTime: Date,
        endTime: Date? = nil,
        isPaid: Bool? = nil,
        note: String = ""
    ) {
        self.id = id
        self.shift = shift
        self.typeRaw = type.rawValue
        self.startTime = startTime
        self.endTime = endTime
        self.isPaid = isPaid ?? type.defaultPaid
        self.note = note
    }

    var type: ActivityType {
        get { ActivityType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
