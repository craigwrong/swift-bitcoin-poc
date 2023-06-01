import Foundation

extension Data {
    private static let regex = try! NSRegularExpression(pattern: "([0-9a-fA-F]{2})", options: [])
    
    /// Create instance from string containing hex digits.
    init(hex: String) {
        let range = NSRange(location: 0, length: hex.count)
        let bytes = Self.regex.matches(in: hex, options: [], range: range)
            .compactMap { Range($0.range(at: 1), in: hex) }
            .compactMap { UInt8(hex[$0], radix: 16) }
        self.init(bytes)
    }
    
}

extension DataProtocol {
    
    /// Hexadecimal (Base-16) string representation of data.
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
