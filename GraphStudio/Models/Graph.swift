import Foundation

/// A complete, saveable graph: metadata, chart type, styled series, and style.
public struct Graph: Codable, Identifiable, Hashable, Sendable {
    public var id = UUID()
    public var title: String
    public var chartType: ChartType
    public var series: [Series]
    public var style: GraphStyle
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "Untitled Graph",
        chartType: ChartType = .line,
        series: [Series] = [],
        style: GraphStyle = .default,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.chartType = chartType
        self.series = series
        self.style = style
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
