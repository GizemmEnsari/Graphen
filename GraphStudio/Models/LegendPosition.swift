import Foundation

public enum LegendPosition: String, Codable, CaseIterable, Sendable {
    case hidden
    case top
    case bottom
    case leading
    case trailing

    public var displayName: String {
        switch self {
        case .hidden: return "Hidden"
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .leading: return "Leading"
        case .trailing: return "Trailing"
        }
    }
}
