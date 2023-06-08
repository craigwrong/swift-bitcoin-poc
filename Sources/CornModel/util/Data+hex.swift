import Foundation

extension Data {
    
    /// Create instance from string containing hex digits.
    init(hex: String) {
        guard let regex = try? NSRegularExpression(pattern: "([0-9a-fA-F]{2})", options: []) else {
            fatalError()
        }
        let range = NSRange(location: 0, length: hex.count)
        let bytes = regex.matches(in: hex, options: [], range: range)
            .compactMap { Range($0.range(at: 1), in: hex) }
            .compactMap { UInt8(hex[$0], radix: 16) }
        self.init(bytes)
    }

    var isZero: Bool {
        reduce(true) { $0 && $1 == 0 }
    }
}

extension DataProtocol {
    
    /// Hexadecimal (Base-16) string representation of data.
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
