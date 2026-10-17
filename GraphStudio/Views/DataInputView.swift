//
//  DataInputView.swift
//  GraphStudio
//
//  Edit the data behind a graph: rename/remove series, add points by hand,
//  import CSV, or plot a mathematical equation.
//

import SwiftUI

struct DataInputView: View {
    @Binding var graph: Graph
    @ObservedObject var store: GraphStore

    @State private var newX = ""
    @State private var newY = ""
    @State private var newLabel = ""
    @State private var addIndex = 0

    @State private var showingCSV = false
    @State private var showingEquation = false
    @State private var confirmingDeleteAll = false
    @State private var status: String?

    var body: some View {
        Form {
            Section("Title") {
                TextField("Graph title", text: $graph.title)
            }

            Section("Series") {
                ForEach(graph.series.indices, id: \.self) { index in
                    let series = graph.series[index]
                    HStack {
                        Circle()
                            .fill(series.color.color)
                            .frame(width: 12, height: 12)
                        Text(series.name)
                        Spacer()
                        Text("\(series.points.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Button(role: .destructive) {
                            graph.series.remove(at: index)
                            if addIndex >= graph.series.count {
                                addIndex = max(0, graph.series.count - 1)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Button {
                    addSeries()
                } label: {
                    Label("Add Series", systemImage: "plus")
                }
            }

            if !graph.series.isEmpty {
                Section("Add Point") {
                    Picker("Add to series", selection: $addIndex) {
                        ForEach(graph.series.indices, id: \.self) { index in
                            Text(graph.series[index].name).tag(index)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 12) {
                        TextField("X value", text: $newX)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .monospaced))
                        TextField("Y value", text: $newY)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .monospaced))
                    }
                    TextField("Label (optional)", text: $newLabel)

                    Button {
                        addPoint()
                    } label: {
                        Label("Add point", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newX.isEmpty || newY.isEmpty)
                }

                if graph.series.indices.contains(addIndex) {
                    pointsSection(index: addIndex)
                }
            }

            if graph.pointCount > 0 {
                Section {
                    Button(role: .destructive) {
                        confirmingDeleteAll = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data Points")
                    Text("\(graph.pointCount) point\(graph.pointCount == 1 ? "" : "s") across \(graph.series.count) series")
                }
            }

            Section("Import") {
                Button {
                    showingCSV = true
                } label: {
                    Label("Import CSV…", systemImage: "doc.text")
                }
                Button {
                    showingEquation = true
                } label: {
                    Label("Plot Equation…", systemImage: "function")
                }
            }

            if let status {
                Section {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingCSV) {
            CSVImportSheet { text in
                importCSV(text)
            }
        }
        .sheet(isPresented: $showingEquation) {
            EquationSheet { expression, min, max, samples in
                plotEquation(expression, min: min, max: max, samples: samples)
            }
        }
        .alert(
            "Delete all data points?",
            isPresented: $confirmingDeleteAll,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteAllData() }
            },
            message: {
                Text("This will remove every data point from all \(graph.series.count) series. Your series names and colors stay, but the points can't be recovered. Are you sure?")
            }
        )
        // Tap a non-interactive area to hide the on-screen keyboard.
        .dismissKeyboardOnTap()
    }

    // MARK: - Points section

    @ViewBuilder
    private func pointsSection(index: Int) -> some View {
        Section {
            if graph.series[index].points.isEmpty {
                Text("No points yet — enter an X and Y value above and tap Add point.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(graph.series[index].points, id: \.id) { point in
                HStack {
                    Circle()
                        .fill(graph.series[index].color.color)
                        .frame(width: 10, height: 10)
                    Text("(\(trimDouble(point.x)), \(trimDouble(point.y)))")
                        .monospacedDigit()
                    if let label = point.label {
                        Text("· \(label)").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        graph.series[index].points.removeAll { $0.id == point.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        } header: {
            Text("Points · \(graph.series[index].name)")
        } footer: {
            Text("\(graph.series[index].points.count) point\(graph.series[index].points.count == 1 ? "" : "s") in this series. Tap the × on a row to remove it.")
        }
    }

    // MARK: - Actions

    private func addSeries() {
        let color = store.nextColor(for: graph)
        graph.series.append(Series(name: "Series \(graph.series.count + 1)",
                                   color: color,
                                   points: []))
    }

    private func addPoint() {
        guard let x = Double(newX), let y = Double(newY) else {
            status = "Enter valid numbers for x and y."
            return
        }
        let index = min(addIndex, graph.series.count - 1)
        graph.series[index].points.append(
            DataPoint(x: x, y: y, label: newLabel.isEmpty ? nil : newLabel)
        )
        newX = ""
        newY = ""
        newLabel = ""
        status = "Added point."
    }

    /// Clears every point from every series while keeping the series structure
    /// (names, colors, styling) intact. Only reachable through the confirmation
    /// alert, so an accidental wipe is not possible.
    private func deleteAllData() {
        graph.series = graph.series.map { series in
            var cleared = series
            cleared.points = []
            return cleared
        }
        status = "Deleted all data points."
    }

    private func importCSV(_ text: String) {
        let parsed = CSVParser().parse(text)
        let newSeries = parsed.toSeries()
        guard !newSeries.isEmpty else {
            status = "No numeric data found in the CSV."
            return
        }
        graph.series.append(contentsOf: newSeries)
        status = "Imported \(newSeries.count) series, \(parsed.rows.count) rows."
    }

    private func plotEquation(_ expression: String, min: Double, max: Double, samples: Int) {
        // NOTE: `min`/`max` are parameters here, so they shadow the standard-library
        // functions; avoid calling `max()`/`min()` inside this scope.
        let step: Double = (max <= min || samples < 2) ? 1 : (max - min) / Double(samples - 1)
        do {
            let points = try EquationParser().sample(expression, from: min, to: max, step: step)
            guard !points.isEmpty else {
                status = "That equation has no values in the range."
                return
            }
            let color = store.nextColor(for: graph)
            let name = expression.count > 22 ? String(expression.prefix(22)) + "…" : expression
            graph.series.append(Series(name: name, color: color, points: points))
            status = "Plotted \(points.count) points for \(expression)."
        } catch {
            status = "Could not parse equation: \(error.localizedDescription)"
        }
    }
}

/// Formats a Double compactly for display.
private func trimDouble(_ d: Double) -> String {
    if d == d.rounded() && abs(d) < 1e15 { return String(Int(d)) }
    return String(format: "%.4g", d)
}
