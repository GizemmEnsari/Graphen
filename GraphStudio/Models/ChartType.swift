import Foundation

/// The kind of chart a `Graph` renders.
public enum ChartType: String, Codable, CaseIterable, Sendable {
    case bar
    case line
    case scatter
    case area
    case pie
    case horizontalBar

    public var displayName: String {
        switch self {
        case .bar: return "Bar"
        case .line: return "Line"
        case .scatter: return "Scatter"
        case .area: return "Area"
        case .pie: return "Pie"
        case .horizontalBar: return "Horizontal Bar"
        }
    }

    /// Whether the chart type is meaningful with a categorical (non-numeric) x-axis.
    public var supportsCategoricalXAxis: Bool {
        switch self {
        case .bar, .horizontalBar, .pie: return true
        default: return false
        }
    }

    /// A SF Symbol representing the chart type.
    public var systemImage: String {
        switch self {
        case .bar: return "chart.bar.fill"
        case .line: return "chart.xyaxis.line"
        case .scatter: return "point.3.filled.connected"
        case .area: return "chart.bar.xaxis"
        case .pie: return "circle.grid.2x2.fill"
        case .horizontalBar: return "chart.bar.horizontal.fill"
        }
    }
}
