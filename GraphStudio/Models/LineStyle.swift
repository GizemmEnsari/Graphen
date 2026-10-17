import Foundation

public enum LineStyle: String, Codable, CaseIterable, Sendable {
    case solid
    case dashed
    case dotted

    public var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .dashed: return "Dashed"
        case .dotted: return "Dotted"
        }
    }
}
