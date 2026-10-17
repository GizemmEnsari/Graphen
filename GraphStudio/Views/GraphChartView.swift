//
//  GraphChartView.swift
//  GraphStudio
//
//  The single rendering surface. Honors `Graph.chartType` (line / bar / area /
//  scatter / horizontal bar / pie) and the model's style (grid, legend, colors).
//

import SwiftUI
import Charts

struct GraphChartView: View {
    let graph: Graph
    var height: CGFloat = 300

    /// When `true`, the chart expands to fill the available space instead of
    /// using the fixed `height` (used by the full-screen preview tab).
    var fill: Bool = false

    /// When `true`, the chart is drawn inside a rounded, bordered card.
    /// Disable it for an edge-to-edge, full-screen presentation.
    var chrome: Bool = true

    /// Extra space above the plot so the centered Y-axis label clears any
    /// floating header (used by the full-screen preview). Zero elsewhere.
    var topInset: CGFloat = 0

    /// A graph is categorical when every point in every series carries a label.
    private var categorical: Bool {
        guard !graph.series.isEmpty else { return false }
        return graph.series.allSatisfy { series in
            !series.points.isEmpty && series.points.allSatisfy { $0.label != nil }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Leading top inset (full-screen preview only): pushes the plot — and
            // its vertically-centered "Y Label" — below the floating header so
            // nothing is hidden. Applied as a layout spacer rather than a chart
            // modifier to keep Swift Charts' type-checking fast.
            if topInset > 0 {
                Color.clear.frame(height: topInset)
            }
            chart
                .modifier(FramingModifier(height: height, fill: fill))
                .modifier(ChromeModifier(enabled: chrome, cornerRadius: 12))
        }
        .background(graph.style.backgroundColor.color)
    }

    @ViewBuilder
    private var chart: some View {
        if graph.pointCount == 0 {
            ContentUnavailableView("No Data", systemImage: "chart.xyaxis.line",
                                  description: Text("Add points, import CSV, or plot an equation."))
        } else {
            switch graph.chartType {
            case .pie:
                pieChart
            case .bar where categorical:
                categoricalBarChart
            case .horizontalBar where categorical:
                categoricalBarChart
            default:
                numericChart
            }
        }
    }

    // MARK: - Pie

    private var pieChart: some View {
        Chart {
            ForEach(graph.series.first?.points ?? [], id: \.id) { point in
                SectorMark(
                    angle: .value("Value", point.y),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Label", point.label ?? String(point.x)))
                .cornerRadius(4)
            }
        }
        .chartLegend(graph.style.showLegend ? .automatic : .hidden)
    }

    // MARK: - Categorical bar

    private var categoricalBarChart: some View {
        Chart {
            ForEach(graph.series, id: \.id) { series in
                ForEach(series.points, id: \.id) { point in
                    BarMark(
                        x: .value("Category", point.label ?? String(point.x)),
                        y: .value("y", point.y)
                    )
                    .foregroundStyle(by: .value("Series", series.name))
                }
            }
        }
        .chartForegroundStyleScale(domain: graph.series.map(\.name),
                                   range: graph.series.map(\.color.color))
        .chartXAxisLabel(graph.style.xAxis.label ?? "X Label")
        .chartYAxisLabel(graph.style.yAxis.label ?? "Y Label")
        .chartYScale(domain: graph.yRange)
        .chartLegend(graph.style.showLegend ? .automatic : .hidden)
        .withGrid(graph.style.showGrid)
    }

    private var numericChart: some View {
        Chart {
            ForEach(graph.series, id: \.id) { series in
                switch graph.chartType {
                case .line:
                    ForEach(series.points, id: \.id) { point in
                        LineMark(x: .value("x", point.x), y: .value("y", point.y))
                            .foregroundStyle(by: .value("Series", series.name))
                            .lineStyle(StrokeStyle(lineWidth: series.lineThickness))
                            .interpolationMethod(.catmullRom)
                    }
                case .area:
                    ForEach(series.points, id: \.id) { point in
                        AreaMark(x: .value("x", point.x), y: .value("y", point.y))
                            .foregroundStyle(by: .value("Series", series.name))
                            .opacity(0.4)
                            .interpolationMethod(.monotone)
                    }
                case .scatter:
                    ForEach(series.points, id: \.id) { point in
                        PointMark(x: .value("x", point.x), y: .value("y", point.y))
                            .foregroundStyle(by: .value("Series", series.name))
                            .symbolSize(60)
                    }
                case .horizontalBar:
                    ForEach(series.points, id: \.id) { point in
                        BarMark(x: .value("y", point.y), y: .value("x", point.x))
                            .foregroundStyle(by: .value("Series", series.name))
                    }
                default: // .bar (numeric x); .pie is handled elsewhere
                    ForEach(series.points, id: \.id) { point in
                        BarMark(x: .value("x", point.x), y: .value("y", point.y))
                            .foregroundStyle(by: .value("Series", series.name))
                    }
                }
            }
        }
        .chartForegroundStyleScale(domain: graph.series.map(\.name),
                                   range: graph.series.map(\.color.color))
        .chartXAxisLabel(graph.style.xAxis.label ?? "X Label")
        .chartYAxisLabel(graph.style.yAxis.label ?? "Y Label")
        .chartXScale(domain: graph.xRange)
        .chartYScale(domain: graph.yRange)
        .chartLegend(graph.style.showLegend ? .automatic : .hidden)
        .withGrid(graph.style.showGrid)
    }
}

// MARK: - Framing & chrome modifiers

/// Either pins the chart to a fixed height or lets it fill the available space.
private struct FramingModifier: ViewModifier {
    let height: CGFloat
    let fill: Bool

    func body(content: Content) -> some View {
        if fill {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content.frame(height: height)
        }
    }
}

/// Optionally wraps the chart in a rounded, bordered card. Disabled for the
/// full-screen preview so the chart can bleed edge-to-edge.
private struct ChromeModifier: ViewModifier {
    let enabled: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        } else {
            content
        }
    }
}

// MARK: - Grid modifier

// Swift Charts exposes no dedicated gridline-visibility modifier (there is no
// `chartXGrid`/`chartYGrid` API); gridlines are drawn by the default axes. This
// modifier is intentionally a no-op so `Graph.style.showGrid` stays a valid,
// forward-compatible hook.
private struct GridModifier: ViewModifier {
    let show: Bool
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func withGrid(_ show: Bool) -> some View {
        modifier(GridModifier(show: show))
    }
}
