public enum PixelComparison {
    /// Fraction of RGBA pixels that differ. A dimension/byte-count mismatch is never accepted.
    public static func difference(actual: [UInt8], reference: [UInt8], channelTolerance: UInt8 = 0) -> Double? {
        guard actual.count == reference.count, !actual.isEmpty, actual.count.isMultiple(of: 4) else { return nil }
        var changed = 0
        for index in stride(from: 0, to: actual.count, by: 4) {
            if (0..<4).contains(where: { abs(Int(actual[index + $0]) - Int(reference[index + $0])) > Int(channelTolerance) }) {
                changed += 1
            }
        }
        return Double(changed) / Double(actual.count / 4)
    }
}
