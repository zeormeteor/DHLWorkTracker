import Foundation

enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case loading
    case driving
    case route
    case pickup
    case waiting
    case scanning
    case breakTime
    case other

    var id: String { rawValue }

    var dutchName: String {
        switch self {
        case .loading: "Laden"
        case .driving: "Rijden"
        case .route: "Route"
        case .pickup: "Afhaalpunten"
        case .waiting: "Wachten"
        case .scanning: "Scannen"
        case .breakTime: "Pauze"
        case .other: "Anders"
        }
    }

    var csvName: String {
        switch self {
        case .loading: "Loading"
        case .driving: "Driving"
        case .route: "Route"
        case .pickup: "Pickup"
        case .waiting: "Waiting"
        case .scanning: "Scanning"
        case .breakTime: "Break"
        case .other: "Other"
        }
    }

    var defaultPaid: Bool { self != .breakTime }
}

enum EmployerStatementStatus: String, Codable, CaseIterable, Identifiable {
    case notEntered
    case provisional
    case final

    var id: String { rawValue }

    var dutchName: String {
        switch self {
        case .notEntered: "Nog niet ingevuld"
        case .provisional: "Voorlopig"
        case .final: "Definitief"
        }
    }
}
