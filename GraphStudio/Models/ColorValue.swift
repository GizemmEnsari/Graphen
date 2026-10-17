import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// A dependency-free color stored as a hex string ("#RRGGBB" or "#RRGGBBAA").
///
/// Storing colors as hex — rather than SwiftUI's `Color` — keeps the model layer
/// free of any UI dependency, which matters for:
///   - cross-platform code exporters (SwiftUI / HTML / Python) that must not
///     import SwiftUI,
///   - stable JSON persistence,
///   - deterministic equality and hashing.
public struct ColorValue: Codable, Hashable, Sendable, CustomStringConvertible {
    public var hex: String

    public init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !trimmed.hasPrefix("#") { trimmed = "#" + trimmed }
        self.hex = trimmed
    }

    public var description: String { hex }

    // MARK: - Common palette

    public static let red = ColorValue(hex: "#FF3B30")
    public static let blue = ColorValue(hex: "#007AFF")
    public static let green = ColorValue(hex: "#34C759")
    public static let orange = ColorValue(hex: "#FF9500")
    public static let purple = ColorValue(hex: "#AF52DE")
    public static let gray = ColorValue(hex: "#8E8E93")
    public static let lightGray = ColorValue(hex: "#E5E5EA")
    public static let black = ColorValue(hex: "#000000")
    public static let white = ColorValue(hex: "#FFFFFF")
}

#if canImport(SwiftUI)
extension ColorValue {
    /// Resolved SwiftUI `Color` for charts and views.
    public var color: Color { Color(hex: hex) }
}

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 8:
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
#endif
