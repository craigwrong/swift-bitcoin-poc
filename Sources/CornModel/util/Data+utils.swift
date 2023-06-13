import Foundation

// - MARK: Hexadecimal encoding/decoding

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
}

extension DataProtocol {
    
    /// Hexadecimal (Base-16) string representation of data.
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

// - MARK: Variable Integer (Compact Integer)

extension Data {
    
    /// Converts a 64-bit integer into its compact integer representation – i.e. variable length data.
    init(varInt value: UInt64) {
        if value < 0xfd {
            var valueVar = UInt8(value)
            self.init(bytes: &valueVar, count: MemoryLayout.size(ofValue: valueVar))
        } else if value <= UInt16.max {
            self = Data([0xfd]) + Swift.withUnsafeBytes(of: UInt16(value)) { Data($0) }
        } else if value <= UInt32.max {
            self = Data([0xfe]) + Swift.withUnsafeBytes(of: UInt32(value)) { Data($0) }
        } else {
            self = Data([0xff]) + Swift.withUnsafeBytes(of: value) { Data($0) }
        }
    }
    
    /// Parses bytes interpreted as variable length – i.e. compact integer – data into a 64-bit integer.
    var varInt: UInt64 {
        guard let firstByte = first else {
            fatalError("Data is empty.")
        }
        
        let tail = dropFirst()
        
        if firstByte < 0xfd {
            return UInt64(firstByte)
        }
        if firstByte == 0xfd {
            let value = tail.withUnsafeBytes {
                $0.load(as: UInt16.self)
            }
            return UInt64(value)
        }
        if firstByte == 0xfd {
            let value = tail.withUnsafeBytes {
                $0.load(as: UInt32.self)
            }
            return UInt64(value)
        }
        let value = tail.withUnsafeBytes {
            $0.load(as: UInt64.self)
        }
        return value
    }
}

extension UInt64 {
    
    var varIntSize: Int {
        switch self {
        case 0 ..< 0xfd:
            return 1
        case 0xfd ... UInt64(UInt16.max):
            return 1 + MemoryLayout<UInt16>.size
        case UInt64(UInt16.max) + 1 ... UInt64(UInt32.max):
            return 1 + MemoryLayout<UInt32>.size
        case UInt64(UInt32.max) + 1 ... UInt64.max:
            return 1 + MemoryLayout<UInt64>.size
        default:
            fatalError()
        }
    }
}

// - MARK: Variable length array

extension Data {
    
    init(varLenData: Data) {
        var data = varLenData
        let contentLen = data.varInt
        data = data.dropFirst(contentLen.varIntSize)
        self = data[..<(data.startIndex + Int(contentLen))]
    }
    
    var varLenData: Data {
        let contentLenData = Data(varInt: UInt64(count))
        return contentLenData + self
    }
    
    /// Memory size as variable length byte array (array prefixed with its element count as compact integer).
    var varLenSize: Int {
        UInt64(count).varIntSize + count
    }
}

extension Array where Element == Data {
    
    /// Memory size as multiple variable length arrays.
    var varLenSize: Int {
        reduce(0) { $0 + $1.varLenSize }
    }
}


// - MARK: Stack utils

extension Data {

    static let zero = Self()
    static let one = {
        Swift.withUnsafeBytes(of: UInt8(1)) { Data($0) }
    }()

    var isZero: Bool { self == .zero }
    var isFalse: Bool { self == .zero }
    var isTrue: Bool { self == .one }
    var isFalseIsh: Bool { isZeroIsh }
    var isTrueIsh: Bool { !isZeroIsh }

    var isZeroIsh: Bool {
        reduce(true) { $0 && $1 == 0 }
    }

    var asUInt32: UInt32 {
        let padded = self + Data(repeating: 0, count: MemoryLayout<UInt32>.size - count)
        return padded.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}

extension Array where Element == Data {
    
    mutating func popUInt8() -> UInt8 {
        let d = self.removeLast()
        return d.withUnsafeBytes {
            $0.load(as: UInt8.self)
        }
    }
    
    mutating func pushInt(_ k: UInt8) {
        append(Swift.withUnsafeBytes(of: k) { Data($0) })
    }

    mutating func pushInt(_ k: UInt32) {
        if k <= UInt8.max {
            pushInt(UInt8(k))
        } else if k <= UInt16.max {
            let d = Swift.withUnsafeBytes(of: UInt16(k)) { Data($0) }
            append(d)
        } else {
            let d = Swift.withUnsafeBytes(of: k) { Data($0) }
            append(d)
        }
    }
    
    mutating func pushBool(_ b: Bool) {
        append(b ? Data.one : Data.zero)
    }
}
