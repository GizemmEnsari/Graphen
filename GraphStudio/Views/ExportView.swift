//
//  ExportView.swift
//  GraphStudio
//
//  Export the graph as a PNG image (via the share sheet) or as code for
//  SwiftUI / HTML (Chart.js) / Python (Matplotlib).
//

import SwiftUI

// MARK: - Export tab

struct ExportView: View {
    @Binding var graph: Graph

    @State private var showingCode = false
    @State private var sharing: ShareItem?

    var body: some View {
        Form {
            Section("Preview") {
                GraphChartView(graph: graph, height: 240)
            }
            Section("Image") {
                Button {
                    shareImage()
                } label: {
                    Label("Export as PNG", systemImage: "photo")
                }
                Text("Renders the chart to an image and opens the share sheet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Code") {
                Button {
                    showingCode = true
                } label: {
                    Label("Generate Code", systemImage: "curlybraces")
                }
                Text("Export a self-contained SwiftUI, HTML (Chart.js), or Python (Matplotlib) snippet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingCode) {
            NavigationStack {
                CodeExportView(graph: graph)
            }
        }
        .sheet(item: $sharing) { item in
            ShareSheet(shareItem: item)
        }
    }

    private func shareImage() {
        guard let data = GraphImage.pngData(from: graph) else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GraphStudio-\(graph.id.uuidString).png")
        try? data.write(to: url)
        sharing = ShareItem(url: url)
    }
}

/// Wraps a `URL` so it can drive a `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Renders a `Graph` to PNG data with `ImageRenderer` (main-actor only).
@MainActor
enum GraphImage {
    static func pngData(from graph: Graph) -> Data? {
        let content = GraphChartView(graph: graph, height: 480)
            .padding()
            .frame(width: 800)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }
}

// MARK: - Share sheet

struct ShareSheet: View {
    let shareItem: ShareItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ShareLink(item: shareItem.url) {
                    Label("Share PNG", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                Text("Tap to share the rendered PNG of your graph.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Code export screen

struct CodeExportView: View {
    let graph: Graph
    @Environment(\.dismiss) private var dismiss
    @State private var language: CodeLanguage = .swiftUI
    @State private var copied = false

    private var code: String {
        switch language {
        case .swiftUI: SwiftUIExporter().export(graph)
        case .htmlChartJS: HTMLChartJSExporter().export(graph)
        case .pythonMatplotlib: PythonMatplotlibExporter().export(graph)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Language", selection: $language) {
                ForEach(CodeLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            ScrollView {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .background(Color(.secondarySystemBackground))

            HStack {
                Button {
                    UIPasteboard.general.string = code
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .onChange(of: language) { _, _ in copied = false }

                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Generate Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}