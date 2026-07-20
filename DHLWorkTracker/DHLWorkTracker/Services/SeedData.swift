import Foundation
import SwiftData

enum SeedData {
    static func ensureDefaults(context: ModelContext) {
        let settingsFetch = FetchDescriptor<AppSettings>()
        let rateFetch = FetchDescriptor<HourlyRate>()
        let shiftFetch = FetchDescriptor<Shift>()

        if (try? context.fetch(settingsFetch).isEmpty) == true {
            context.insert(AppSettings())
        }
        if (try? context.fetch(rateFetch).isEmpty) == true {
            PayrollEngine.defaultHourlyRates().forEach(context.insert)
        }
        if (try? context.fetch(shiftFetch).isEmpty) == true {
            sampleShifts().forEach(context.insert)
        }
        try? context.save()
    }

    static func sampleShifts(calendar: Calendar = .current) -> [Shift] {
        [
            makeShift("2026-07-02", [
                (.loading, "09:45", "10:30"),
                (.driving, "10:30", "10:50"),
                (.route, "10:50", "18:30"),
                (.pickup, "18:30", "19:20"),
                (.driving, "19:20", "19:45"),
                (.scanning, "19:45", "21:00")
            ], calendar: calendar),
            makeShift("2026-07-03", [
                (.loading, "17:00", "17:30"),
                (.route, "17:30", "20:00"),
                (.scanning, "20:00", "20:30")
            ], calendar: calendar),
            makeShift("2026-07-04", [
                (.loading, "09:45", "10:30"),
                (.route, "10:30", "18:30"),
                (.pickup, "18:30", "19:30"),
                (.driving, "19:30", "20:15"),
                (.scanning, "20:15", "21:00")
            ], calendar: calendar)
        ]
    }

    private static func makeShift(_ day: String, _ rows: [(ActivityType, String, String)], calendar: Calendar) -> Shift {
        let start = date(day, rows.first!.1, calendar: calendar)
        let end = date(day, rows.last!.2, calendar: calendar)
        let shift = Shift(date: calendar.startOfDay(for: start), startTime: start, endTime: end, notes: "Voorbeelddata")
        shift.segments = rows.map {
            WorkSegment(shift: shift, type: $0.0, startTime: date(day, $0.1, calendar: calendar), endTime: date(day, $0.2, calendar: calendar))
        }
        return shift
    }

    private static func date(_ day: String, _ time: String, calendar: Calendar) -> Date {
        let dayParts = day.split(separator: "-").compactMap { Int($0) }
        let timeParts = time.split(separator: ":").compactMap { Int($0) }
        return calendar.date(from: DateComponents(year: dayParts[0], month: dayParts[1], day: dayParts[2], hour: timeParts[0], minute: timeParts[1]))!
    }
}
