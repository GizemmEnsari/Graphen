import Foundation

/// Configuration for a single axis (x or y).
public struct AxisConfig: Codable, Hashable, Sendable {
    public var show: Bool
    public var label: String?
    public var scale: AxisScale
    public var showGrid: Bool
    public var showTicks: Bool

    public init(
        show: Bool = true,
        label: String? = nil,
        scale: AxisScale = .linear,
        showGrid: Bool = true,
        showTicks: Bool = true
    ) {
        self.show = show
        self.label = label
        self.scale = scale
        self.showGrid = showGrid
        self.showTicks = showTicks
    }
}
