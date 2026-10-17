import Foundation

public extension Graph {
    /// A small, colorful demo graph useful for previews and the empty state.
    static var sample: Graph {
        var graph = Graph(
            title: "Sample: Sales by Quarter",
            chartType: .bar
        )
        graph.series = [
            Series(
                name: "2024",
                color: .blue,
                points: [
                    .init(x: 1, y: 40, label: "Q1"),
                    .init(x: 2, y: 65, label: "Q2"),
                    .init(x: 3, y: 55, label: "Q3"),
                    .init(x: 4, y: 80, label: "Q4")
                ]
            ),
            Series(
                name: "2025",
                color: .green,
                points: [
                    .init(x: 1, y: 50, label: "Q1"),
                    .init(x: 2, y: 70, label: "Q2"),
                    .init(x: 3, y: 90, label: "Q3"),
                    .init(x: 4, y: 85, label: "Q4")
                ]
            )
        ]
        graph.style.xAxis.label = "Quarter"
        graph.style.yAxis.label = "Sales"
        return graph
    }
}
