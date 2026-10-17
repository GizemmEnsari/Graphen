import Foundation

/// Number formatting shared by the code exporters.
enum CodeNumber {
    /// A compact, readable Double literal (integers without a trailing `.0`).
    static func f(_ d: Double) -> String {
        if d.isNormal && d == d.rounded() && abs(d) < 1e15 {
            return String(Int(d))
        }
        return String(format: "%.6g", d)
    }

    static func array(_ values: [Double]) -> String {
        "[" + values.map(f).joined(separator: ", ") + "]"
    }

    static func stringArray(_ values: [String]) -> String {
        "[" + values.map { "\"\(escaped($0))\"" }.joined(separator: ", ") + "]"
    }
}

/// Escapes a string for embedding in source code / JSON.
func escaped(_ s: String) -> String {
    var out = ""
    for ch in s {
        switch ch {
        case "\"": out += "\\\""
        case "\\": out += "\\\\"
        case "\n": out += "\\n"
        case "\t": out += "\\t"
        default: out.append(ch)
        }
    }
    return out
}

extension String {
    /// `#RRGGBB` (or `#RRGGBBAA`) -> (r, g, b) in 0...1. Black for malformed input.
    var rgbComponents: (r: Double, g: Double, b: Double) {
        let cleaned = replacingOccurrences(of: "#", with: "").uppercased()
        let value = UInt64(cleaned, radix: 16) ?? 0
        let r = Double((value & 0xFF00_0000) >> 16) / 255
        let g = Double((value & 0x00FF_0000) >> 8) / 255
        let b = Double(value & 0x0000_FF) / 255
        return (r, g, b)
    }

    /// Best-effort sanitization into a valid source-code identifier.
    var validIdentifier: String {
        var result = ""
        for (offset, ch) in self.enumerated() {
            if ch.isLetter || ch.isNumber || ch == "_" {
                result.append(ch)
            } else if offset == 0 {
                result.append("_")
            }
        }
        let cleaned = result.prefix(while: { !$0.isNumber })
        return cleaned.isEmpty ? "Graph" : String(cleaned)
    }
}

extension ColorValue {
    /// A SwiftUI `Color(...)` literal built from this hex value.
    var swiftUIColorLiteral: String {
        let c = hex.rgbComponents
        return "Color(red: \(CodeNumber.f(c.r)), green: \(CodeNumber.f(c.g)), blue: \(CodeNumber.f(c.b)))"
    }
}