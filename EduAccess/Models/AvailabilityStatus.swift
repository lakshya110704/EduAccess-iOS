//
//  AvailabilityStatus.swift
//  EduAccess
//
//  A professor's real-time availability, mirroring the web platform's
//  Free / Busy / Unavailable states.
//
import UIKit

enum AvailabilityStatus: String, Codable, CaseIterable {
    case free = "Free"
    case busy = "Busy"
    case unavailable = "Unavailable"

    /// Human-readable label shown in the UI.
    var displayText: String { rawValue }

    /// Indicator color used for the status dot.
    var color: UIColor {
        switch self {
        case .free:        return UIColor(red: 47/255, green: 191/255, blue: 154/255, alpha: 1.0) // app green
        case .busy:        return .systemOrange
        case .unavailable: return .systemRed
        }
    }

    /// A small filled-circle image tinted to the status color, for table cells.
    var indicatorImage: UIImage? {
        UIImage(systemName: "circle.fill")?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
