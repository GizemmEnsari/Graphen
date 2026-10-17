import Foundation

public enum AxisScale: String, Codable, CaseIterable, Sendable {
    case linear
    case logarithmic

    public var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .logarithmic: return "Logarithmic"
        }
    }
}
