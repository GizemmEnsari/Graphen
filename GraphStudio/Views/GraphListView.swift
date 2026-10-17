//
//  GraphListView.swift
//  GraphStudio
//
//  Home screen: every saved graph as a row with a live mini-chart. Swipe to
//  delete, tap to open the editor, "+" to create a new graph.
//

import SwiftUI

struct GraphListView: View {
    @ObservedObject var store: GraphStore
    @Binding var path: NavigationPath

    var body: some View {
        List {
            ForEach(store.graphs) { graph in
                NavigationLink(value: graph.id) {
                    GraphRow(graph: graph)
                }
            }
            .onDelete { offsets in
                store.graphs.remove(atOffsets: offsets)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if store.graphs.isEmpty {
                ContentUnavailableView("No Graphs", systemImage: "chart.xyaxis.line",
                                      description: Text("Tap the + button to create your first graph."))
            }
        }
        .navigationTitle("Graphs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let graph = store.addNewGraph()
                    path.append(graph.id)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create new graph")
            }
        }
    }

}

/// A compact preview row: a small chart plus the graph's title and type.
struct GraphRow: View {
    let graph: Graph

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(graph.title.isEmpty ? "Untitled Graph" : graph.title)
                    .font(.headline)
                Spacer()
                Label(graph.chartType.displayName, systemImage: graph.chartType.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GraphChartView(graph: graph, height: 120)
            HStack {
                Text("\(graph.series.count) series · \(graph.pointCount) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(graph.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}