import Foundation

/// A code exporter turns a `Graph` into a code string for a target language.
///
/// This is the "Generate Code" feature: it is just another export format,
/// implemented as string templating over the same model that drives rendering.
/// No code is compiled on-device.
public protocol CodeExporter {
    var language: CodeLanguage { get }
    func export(_ graph: Graph) -> String
}

public enum CodeLanguage: String, Codable, CaseIterable, Sendable {
    case swiftUI
    case htmlChartJS
    case pythonMatplotlib

    public var displayName: String {
        switch self {
        case .swiftUI: return "SwiftUI"
        case .htmlChartJS: return "HTML (Chart.js)"
        case .pythonMatplotlib: return "Python (Matplotlib)"
        }
    }

    public var fileExtension: String {
        switch self {
        case .swiftUI: return "swift"
        case .htmlChartJS: return "html"
        case .pythonMatplotlib: return "py"
        }
    }
}

// TODO(Phase 5): implement SwiftUIExporter, HTMLChartJSExporter, and
// PythonMatplotlibExporter conforming to `CodeExporter`.
