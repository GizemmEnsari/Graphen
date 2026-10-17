//
//  GraphStore.swift
//  GraphStudio
//
//  In-memory store of graphs (Codable value types). UI-independent data
//  layer; SwiftData can replace this later without touching the model.
//

import SwiftUI

/// Observable in-memory store of `Graph` value types.
@MainActor
final class GraphStore: ObservableObject {
    @Published var graphs: [Graph]

    init(graphs: [Graph]? = nil) {
        // The app opens empty — no example or sample graphs are shown by default.
        // Users create their own via the "+" button on the home screen.
        self.graphs = graphs ?? []
    }

    /// Palette cycled when assigning colors to new series.
    nonisolated static let palette: [ColorValue] = [
        .blue, .green, .red, .orange, .purple, .gray,
    ]

    @discardableResult
    func addNewGraph(chartType: ChartType = .line) -> Graph {
        var graph = Graph(title: "New Graph", chartType: chartType)
        // Seed the new graph with a small sample dataset so the preview shows a
        // full, live chart right away (instead of an empty "No Data" screen).
        // The user can edit, add to, or delete these starter points.
        graph.series = [
            Series(
                name: "Series 1",
                color: .blue,
                points: [
                    DataPoint(x: 1, y: 2),
                    DataPoint(x: 2, y: 5),
                    DataPoint(x: 3, y: 3),
                    DataPoint(x: 4, y: 7),
                    DataPoint(x: 5, y: 6),
                    DataPoint(x: 6, y: 9),
                ]
            )
        ]
        graphs.append(graph)
        return graph
    }

    func delete(id: Graph.ID) {
        graphs.removeAll { $0.id == id }
    }

    func index(for id: Graph.ID) -> Int? {
        graphs.firstIndex { $0.id == id }
    }

    /// Next free color in the palette for a graph's series.
    func nextColor(for graph: Graph) -> ColorValue {
        let used = Set(graph.series.map { $0.color.hex })
        for c in GraphStore.palette where !used.contains(c.hex) {
            return c
        }
        return .blue
    }
}