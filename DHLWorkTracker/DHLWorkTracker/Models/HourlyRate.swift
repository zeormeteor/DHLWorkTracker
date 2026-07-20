import Foundation
import SwiftData

@Model
final class HourlyRate {
    @Attribute(.unique) var id: UUID
    var effectiveFrom: Date
    var effectiveUntil: Date?
    var rate: Decimal

    init(id: UUID = UUID(), effectiveFrom: Date, effectiveUntil: Date? = nil, rate: Decimal) {
        self.id = id
        self.effectiveFrom = effectiveFrom
        self.effectiveUntil = effectiveUntil
        self.rate = rate
    }
}
