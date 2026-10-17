import Foundation

/// Visual customization for a `Graph`: colors, fonts, grid, legend, axes.
public struct GraphStyle: Codable, Hashable, Sendable {
    public var backgroundColor: ColorValue
    public var gridColor: ColorValue
    public var textColor: ColorValue

    public var showGrid: Bool
    public var showLegend: Bool
    public var legendPosition: LegendPosition
    public var legendFontSize: Double
    public var titleFontSize: Double

    public var xAxis: AxisConfig
    public var yAxis: AxisConfig

    public init(
        backgroundColor: ColorValue = .white,
        gridColor: ColorValue = .lightGray,
        textColor: ColorValue = .black,
        showGrid: Bool = true,
        showLegend: Bool = true,
        legendPosition: LegendPosition = .trailing,
        legendFontSize: Double = 12,
        titleFontSize: Double = 18,
        xAxis: AxisConfig = AxisConfig(label: "X Label"),
        yAxis: AxisConfig = AxisConfig(label: "Y Label")
    ) {
        self.backgroundColor = backgroundColor
        self.gridColor = gridColor
        self.textColor = textColor
        self.showGrid = showGrid
        self.showLegend = showLegend
        self.legendPosition = legendPosition
        self.legendFontSize = legendFontSize
        self.titleFontSize = titleFontSize
        self.xAxis = xAxis
        self.yAxis = yAxis
    }

    /// A sensible starting style used when creating a new graph.
    public static let `default` = GraphStyle()
}
