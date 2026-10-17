//
//  StyleView.swift
//  GraphStudio
//
//  Customize chart type, axis labels, grid/legend, and per-series colors.
//

import SwiftUI

struct StyleView: View {
    @Binding var graph: Graph

    private var xLabelBinding: Binding<String> {
        Binding(
            get: { graph.style.xAxis.label ?? "" },
            set: { graph.style.xAxis.label = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0.trimmingCharacters(in: .whitespaces) }
        )
    }

    private var yLabelBinding: Binding<String> {
        Binding(
            get: { graph.style.yAxis.label ?? "" },
            set: { graph.style.yAxis.label = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0.trimmingCharacters(in: .whitespaces) }
        )
    }

    var body: some View {
        Form {
            Section("Chart Type") {
                Picker("Type", selection: $graph.chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImage).tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Axes") {
                HStack {
                    Text("X axis label").foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. Time", text: xLabelBinding)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Y axis label").foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. Sales", text: yLabelBinding)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }
                Toggle("Show grid", isOn: $graph.style.showGrid)
                Toggle("Show legend", isOn: $graph.style.showLegend)
                if graph.style.showLegend {
                    Picker("Legend", selection: $graph.style.legendPosition) {
                        ForEach(LegendPosition.allCases, id: \.self) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Section("Series Colors") {
                ForEach(graph.series.indices, id: \.self) { index in
                    HStack {
                        Text(graph.series[index].name)
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(GraphStore.palette, id: \.self) { color in
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                graph.series[index].color == color
                                                    ? Color.primary.opacity(0.6)
                                                    : Color.gray.opacity(0.25),
                                                lineWidth: graph.series[index].color == color ? 3 : 1.5
                                            )
                                    )
                                    .onTapGesture { graph.series[index].color = color }
                            }
                        }
                    }
                }
                if graph.series.isEmpty {
                    Text("No series yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        // Tap a non-interactive area to hide the on-screen keyboard.
        .dismissKeyboardOnTap()
    }
}