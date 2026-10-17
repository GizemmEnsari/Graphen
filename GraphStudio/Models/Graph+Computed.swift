import Foundation

public extension Graph {
    /// Every plottable point across all series, ignoring non-finite values.
    var allPoints: [DataPoint] {
        series.flatMap(\.points).filter(\.isFinite)
    }

    /// Minimum and maximum x across all series (clamped when all equal or empty).
    var xRange: ClosedRange<Double> {
        let xs = allPoints.map(\.x)
        if xs.isEmpty { return 0...1 }
        let min = xs.min() ?? 0
        let max = xs.max() ?? 1
        return min == max ? (min - 1)...(max + 1) : min...max
    }

    /// Minimum and maximum y across all series (clamped when all equal or empty).
    var yRange: ClosedRange<Double> {
        let ys = allPoints.map(\.y)
        if ys.isEmpty { return 0...1 }
        let min = ys.min() ?? 0
        let max = ys.max() ?? 1
        return min == max ? (min - 1)...(max + 1) : min...max
    }

    /// Total number of data points across every series.
    var pointCount: Int {
        series.reduce(0) { $0 + $1.points.count }
    }

    /// Returns a copy with `modifiedAt` set to now (used for autosave).
    func touching() -> Graph {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }
}
