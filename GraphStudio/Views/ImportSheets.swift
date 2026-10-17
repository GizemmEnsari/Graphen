//
//  ImportSheets.swift
//  GraphStudio
//
//  Sheet dialogs for CSV import and equation plotting.
//

import SwiftUI

/// A text editor for pasting/prescribing CSV, with a sensible sample.
struct CSVImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = CSVImportSheet.sampleCSV
    var onImport: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("CSV Data") {
                    TextEditor(text: $text)
                        .frame(minHeight: 220)
                        .font(.system(.body, design: .monospaced))
                }
                Section {
                    Text("Column 1 is the x-axis; each other column becomes a series. The first row may be a header. Non-numeric x values are treated as category labels.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // Tap the empty area to hide the on-screen keyboard.
            .dismissKeyboardOnTap()
        }
    }

    static let sampleCSV = """
    Quarter,Sales,Profit
    Q1,75,20
    Q2,130,55
    Q3,155,60
    Q4,190,95
    """
}

/// A dialog for plotting a mathematical equation over a range.
struct EquationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expression = "sin(x)"
    @State private var minText = "-6.28"
    @State private var maxText = "6.28"
    @State private var samplesText = "200"
    var onPlot: (String, Double, Double, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Expression") {
                    TextField("y = …", text: $expression)
                        .font(.system(.body, design: .monospaced))
                    Text("Use x with + - * / ^ and functions: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, exp, ln, log, sqrt, cbrt, abs, floor, ceil. Constants: pi, e.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Domain") {
                    LabeledContent("From x") {
                        TextField("-6.28", text: $minText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    LabeledContent("To x") {
                        TextField("6.28", text: $maxText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    LabeledContent("Samples") {
                        TextField("200", text: $samplesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Plot Equation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Plot") {
                        let min = Double(minText) ?? -6.28
                        let max = Double(maxText) ?? 6.28
                        let samples = Int(samplesText) ?? 200
                        onPlot(expression, min, max, samples)
                        dismiss()
                    }
                    .disabled(expression.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            // Tap the empty area to hide the on-screen keyboard.
            .dismissKeyboardOnTap()
        }
    }
}