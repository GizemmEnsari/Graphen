import Foundation

/// A single (x, y) coordinate within a `Series`.
///
/// `x`/`y` are `Double` so any value — numeric or datetime (as a timestamp) —
/// can be plotted on a numeric axis. Categorical axes use `label` instead of `x`.
public struct DataPoint: Codable, Identifiable, Hashable, Sendable {
    public var id = UUID()
    public var x: Double
    public var y: Double

    /// Optional human-readable label: used for pie slices, categorical axes,
    /// and tooltips. When nil, the `x` value is used as the category.
    public var label: String?

    public init(id: UUID = UUID(), x: Double, y: Double, label: String? = nil) {
        self.id = id
        self.x = x
        self.y = y
        self.label = label
    }

    /// Whether both coordinates are finite and therefore plottable.
    public var isFinite: Bool {
        x.isFinite && y.isFinite
    }
}
