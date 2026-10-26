public enum PixelComparison {
    /// Fraction of RGBA pixels that differ. A dimension/byte-count mismatch is never accepted.
    public static func difference(actual: [UInt8], reference: [UInt8]) -> Double? {
        guard actual.count == reference.count, !actual.isEmpty, actual.count.isMultiple(of: 4) else { return nil }
        var changed = 0
        for index in stride(from: 0, to: actual.count, by: 4) {
            if actual[index..<(index + 4)] != reference[index..<(index + 4)] { changed += 1 }
        }
        return Double(changed) / Double(actual.count / 4)
    }
}
