import Foundation

/// Default color cycled for auto-named series.
let csvDefaultPalette: [ColorValue] = [
    .blue, .green, .red, .orange, .purple, .gray,
]

/// A parsed CSV: a header row (if detected) plus data rows and the detected delimiter.
public struct ParsedCSV {
    public var headers: [String]
    public var rows: [[String]]
    public var delimiter: Character

    public init(headers: [String], rows: [[String]], delimiter: Character) {
        self.headers = headers
        self.rows = rows
        self.delimiter = delimiter
    }
}

/// A CSV parser supporting quoted fields, embedded delimiters/newlines, and
/// multiple delimiter types (comma, tab, semicolon, pipe).
///
/// The parser is a small state machine over the character stream. It handles
/// RFC-4180 style double-quote escaping (`""`) and auto-detects the delimiter
/// from the first line.
public struct CSVParser {
    public init() {}

    /// Parses raw CSV text, auto-detecting the delimiter and a header row.
    public func parse(_ content: String) -> ParsedCSV {
        let firstLine = content.prefix(while: { $0 != "\n" && $0 != "\r" })
        let delimiter = Self.detectDelimiter(String(firstLine))

        let chars = Array(content)
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
                i += 1
                continue
            }
            switch c {
            case "\"":
                inQuotes = true
                i += 1
            case delimiter:
                record.append(field)
                field = ""
                i += 1
            case "\n":
                record.append(field)
                field = ""
                records.append(record)
                record = []
                i += 1
            case "\r":
                record.append(field)
                field = ""
                records.append(record)
                record = []
                if i + 1 < chars.count && chars[i + 1] == "\n" { i += 1 }
                i += 1
            default:
                field.append(c)
                i += 1
            }
        }
        // Flush any trailing field / record.
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            records.append(record)
        }

        let cleaned = records
            .map { $0.map { $0.trimmingCharacters(in: .whitespaces) } }
            .filter { $0.contains { !$0.isEmpty } }

        if cleaned.isEmpty {
            return ParsedCSV(headers: [], rows: [], delimiter: delimiter)
        }

        // A header is present when the first row has a non-numeric cell and there
        // is at least one more row.
        let first = cleaned[0]
        let looksLikeHeader = first.contains { !$0.isEmpty && Double($0) == nil }
        if looksLikeHeader && cleaned.count > 1 {
            return ParsedCSV(headers: first, rows: Array(cleaned.dropFirst()), delimiter: delimiter)
        }
        return ParsedCSV(headers: [], rows: cleaned, delimiter: delimiter)
    }

    /// Picks the delimiter that appears most often on the first line.
    private static func detectDelimiter(_ line: String) -> Character {
        let candidates: [Character] = [",", "\t", ";", "|"]
        var best: Character = ","
        var bestCount = -1
        for c in candidates {
            let count = line.filter { $0 == c }.count
            if count > bestCount {
                bestCount = count
                best = c
            }
        }
        return best
    }
}

public struct CSVParsingError: Error, CustomStringConvertible {
    public let message: String
    public init(message: String) { self.message = message }
    public var description: String { message }
}

extension ParsedCSV {
    /// Builds `Series` from parsed CSV data.
    ///
    /// - Column 0 is the x-axis (numeric or categorical).
    /// - Each remaining column becomes a series; if there is only one column it
    ///   is treated as the y-values with an index x-axis.
    /// - Non-numeric x values become categorical labels (x = row index).
    func toSeries(palette: [ColorValue] = csvDefaultPalette) -> [Series] {
        guard !rows.isEmpty else { return [] }
        let columnCount = rows.map(\.count).max() ?? 1
        guard columnCount >= 1 else { return [] }

        let firstColumn = rows.map { $0.indices.contains(0) ? $0[0] : "" }
        let xIsNumeric = firstColumn.allSatisfy { $0.isEmpty || Double($0) != nil }

        let valueColumns: Range<Int>
        let hasSeparateX: Bool
        if columnCount >= 2 {
            valueColumns = 1..<columnCount
            hasSeparateX = true
        } else {
            valueColumns = 0..<1
            hasSeparateX = false
        }

        var series: [Series] = []
        for (offset, col) in valueColumns.enumerated() {
            let fallback = "Series \(offset + 1)"
            let name = col < headers.count
                ? (headers[col].isEmpty ? fallback : headers[col])
                : fallback

            var points: [DataPoint] = []
            var index = 0
            for row in rows {
                let yCell = row.indices.contains(col) ? row[col] : ""
                if let y = Double(yCell), y.isFinite {
                    let x: Double
                    let label: String?
                    if hasSeparateX {
                        let xCell = row.indices.contains(0) ? row[0] : ""
                        if xIsNumeric {
                            x = Double(xCell) ?? Double(index)
                            label = nil
                        } else {
                            x = Double(index)
                            label = xCell.isEmpty ? nil : xCell
                        }
                    } else {
                        x = Double(index)
                        label = nil
                    }
                    points.append(DataPoint(x: x, y: y, label: label))
                }
                index += 1
            }

            if !points.isEmpty {
                series.append(Series(name: name,
                                     color: palette[offset % palette.count],
                                     points: points))
            }
        }
        return series
    }
}
