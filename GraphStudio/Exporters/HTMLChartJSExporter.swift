import Foundation

/// Generates a standalone HTML page that renders the graph with Chart.js.
public struct HTMLChartJSExporter: CodeExporter {
    public var language: CodeLanguage { .htmlChartJS }
    public init() {}

    public func export(_ graph: Graph) -> String {
        var datasets: [String] = []
        let labels = categoryLabels(graph)
        let chartType = htmlChartType(graph.chartType)

        for series in graph.series {
            let data = CodeNumber.array(series.points.map(\.y))
            datasets.append(
                """
                {
                  label: \(json(series.name)),
                  data: \(data),
                  borderColor: \(json(series.color.hex)),
                  backgroundColor: \(json(series.color.hex + "33")),
                  fill: \(graph.chartType == .area ? "true" : "false"),
                  tension: 0.3
                }
                """
            )
        }

        var lines: [String] = []
        lines.append("<!DOCTYPE html>")
        lines.append("<html lang=\"en\">")
        lines.append("<head>")
        lines.append("  <meta charset=\"UTF-8\" />")
        lines.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />")
        lines.append("  <title>\(escaped(graph.title))</title>")
        lines.append("  <script src=\"https://cdn.jsdelivr.net/npm/chart.js\"></script>")
        lines.append("</head>")
        lines.append("<body style=\"font-family: -apple-system, system-ui; margin: 24px;\">")
        lines.append("  <h1>\(escaped(graph.title))</h1>")
        lines.append("  <canvas id=\"chart\" style=\"max-width: 800px;\"></canvas>")
        lines.append("  <script>")
        lines.append("  const ctx = document.getElementById('chart');")
        lines.append("  new Chart(ctx, {")
        lines.append("    type: \(json(chartType)),")
        lines.append("    data: {")
        lines.append("      labels: \(labels),")
        lines.append("      datasets: [\(datasets.joined(separator: ","))]")
        lines.append("    },")
        lines.append("    options: {")
        lines.append("      responsive: true,")
        lines.append("      plugins: {")
        lines.append("        title: { display: true, text: \(json(graph.title)) },")
        lines.append("        legend: { display: \(graph.style.showLegend ? "true" : "false") }")
        lines.append("      },")
        lines.append("      scales: {")
        lines.append("        x: { title: { display: true, text: \(json(graph.style.xAxis.label ?? "X Label")) } },")
        lines.append("        y: { title: { display: true, text: \(json(graph.style.yAxis.label ?? "Y Label")) } }")
        lines.append("      }")
        lines.append("    }")
        lines.append("  });")
        lines.append("  </script>")
        lines.append("</body>")
        lines.append("</html>")
        return lines.joined(separator: "\n") + "\n"
    }

    /// Chart.js type for a given model chart type.
    private func htmlChartType(_ type: ChartType) -> String {
        switch type {
        case .bar, .horizontalBar: return "bar"
        case .scatter: return "scatter"
        case .pie: return "pie"
        case .line, .area: return "line"
        }
    }

    /// Category labels (when categorical) or x values, otherwise.
    private func categoryLabels(_ graph: Graph) -> String {
        if let series = graph.series.first,
           series.points.contains(where: { $0.label != nil }) {
            return CodeNumber.stringArray(graph.series.first?.points.map { $0.label ?? String($0.x) } ?? [])
        }
        return CodeNumber.array(graph.series.first?.points.map(\.x) ?? [])
    }

    /// Minimal JSON string quoting.
    private func json(_ s: String) -> String {
        "\"" + escaped(s) + "\""
    }
}