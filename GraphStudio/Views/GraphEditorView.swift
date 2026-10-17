//
//  GraphEditorView.swift
//  GraphStudio
//
//  The per-graph workspace: a TabView over Preview, Data, Style, and Export.
//  Edits flow back to the store through a binding into `store.graphs`.
//

import SwiftUI

struct GraphEditorView: View {
    @ObservedObject var store: GraphStore
    let graphID: Graph.ID
    @Binding var path: NavigationPath
    @State private var tab: EditorTab = .preview

    enum EditorTab: String, CaseIterable, Identifiable, Hashable {
        case preview, data, style, export
        var id: String { rawValue }
        var label: String {
            switch self {
            case .preview: return "Preview"
            case .data: return "Data"
            case .style: return "Style"
            case .export: return "Export"
            }
        }
        var systemImage: String {
            switch self {
            case .preview: return "chart.xyaxis.line"
            case .data: return "list.bullet"
            case .style: return "paintbrush"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    /// A binding into the store's array for this graph, if it still exists.
    private var graphBinding: Binding<Graph>? {
        guard let index = store.index(for: graphID) else { return nil }
        return $store.graphs[index]
    }

    var body: some View {
        Group {
            if let graph = graphBinding {
                TabView(selection: $tab) {
                    PreviewTab(graph: graph, onDelete: delete)
                        .tabItem { Label("Preview", systemImage: "chart.xyaxis.line") }
                        .tag(EditorTab.preview)
                    DataInputView(graph: graph, store: store)
                        .tabItem { Label("Data", systemImage: "list.bullet") }
                        .tag(EditorTab.data)
                    StyleView(graph: graph)
                        .tabItem { Label("Style", systemImage: "paintbrush") }
                        .tag(EditorTab.style)
                    ExportView(graph: graph)
                        .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                        .tag(EditorTab.export)
                }
            } else {
                ContentUnavailableView("Not Found", systemImage: "exclamationmark.triangle",
                                      description: Text("This graph is no longer available."))
            }
        }
        // The Preview tab presents its own edge-to-edge chart with a floating
        // header, so the navigation chrome is hidden there to keep the chart
        // full-screen (no bar overlapping the plot or its axis labels). Other
        // tabs keep the standard "Edit Graph" bar.
        .navigationBarHidden(tab == .preview)
        .navigationTitle("Edit Graph")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    /// Deletes the graph and pops back to the list.
    private func delete() {
        store.delete(id: graphID)
        path.removeLast()
    }
}

/// Preview tab: the chart rendered edge-to-edge across the whole screen, with a
/// compact floating glass header showing the title and chart type.
struct PreviewTab: View {
    @Binding var graph: Graph

    /// Called when the user taps the delete (trash) button in the header.
    var onDelete: () -> Void = {}

    var body: some View {
        ZStack(alignment: .top) {
            // Edge-to-edge chart that fills the entire screen, painting under the
            // status bar and home indicator so there are no black bars top/bottom.
            // The top inset pushes the plot (and its centered "Y Label") below the
            // floating header so nothing is hidden.
            GraphChartView(graph: graph, fill: true, chrome: false, topInset: 120)
                .ignoresSafeArea(.all, edges: .all)

            // Floating glass header with the title and chart-type badge. The top
            // inset respects the status bar so the header never sits under the
            // clock, and it owns the delete action in place of the nav bar.
            header
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .ignoresSafeArea(.container, edges: .top)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(graph.title.isEmpty ? "Untitled Graph" : graph.title)
                    .font(.headline)
                Text("\(graph.pointCount) point\(graph.pointCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label(graph.chartType.displayName, systemImage: graph.chartType.systemImage)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.body.weight(.medium))
            }
            .accessibilityLabel("Delete graph")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}