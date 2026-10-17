import Foundation

public enum MarkerStyle: String, Codable, CaseIterable, Sendable {
    case none
    case circle
    case square
    case triangle
    case diamond

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .circle: return "Circle"
        case .square: return "Square"
        case .triangle: return "Triangle"
        case .diamond: return "Diamond"
        }
    }
}
