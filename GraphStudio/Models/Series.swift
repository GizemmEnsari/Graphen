import Foundation

/// One data series (e.g. "2024 Sales") with its own styling and points.
public struct Series: Codable, Identifiable, Hashable, Sendable {
    public var id = UUID()
    public var name: String
    public var color: ColorValue

    // Line appearance
    public var lineStyle: LineStyle
    public var lineThickness: Double

    // Marker appearance
    public var markerStyle: MarkerStyle
    public var markerSize: Double
    public var showLine: Bool
    public var showMarkers: Bool

    /// Ordered data points. Order matters for line/area charts.
    public var points: [DataPoint]

    public init(
        id: UUID = UUID(),
        name: String = "Series",
        color: ColorValue = .blue,
        lineStyle: LineStyle = .solid,
        lineThickness: Double = 2,
        markerStyle: MarkerStyle = .circle,
        markerSize: Double = 6,
        showLine: Bool = true,
        showMarkers: Bool = true,
        points: [DataPoint] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.lineStyle = lineStyle
        self.lineThickness = lineThickness
        self.markerStyle = markerStyle
        self.markerSize = markerSize
        self.showLine = showLine
        self.showMarkers = showMarkers
        self.points = points
    }
}
