import Foundation
import SwiftUI

// MARK: - Int formatting

extension Int {
    /// Abbreviates large numbers: 1500 → "1.5K", 2_000_000 → "2M"
    var abbreviated: String {
        switch self {
        case 1_000_000...: return "\(self / 1_000_000)M"
        case 1_000...:     return "\(self / 1_000)K"
        default:           return "\(self)"
        }
    }
}

// MARK: - TimeInterval formatting

extension TimeInterval {
    /// Formats seconds as "M:SS"
    var mmss: String {
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Date relative formatting

extension Date {
    /// Short time-remaining string for challenge end dates (positive future interval)
    var relativeShort: String {
        let diff = timeIntervalSinceNow   // positive = future
        guard diff > 0 else { return "Ended" }
        if diff < 3600  { return "\(Int(diff / 60))m left" }
        if diff < 86400 { return "\(Int(diff / 3600))h left" }
        return "\(Int(diff / 86400))d left"
    }
}

// MARK: - Color hex initialiser

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
