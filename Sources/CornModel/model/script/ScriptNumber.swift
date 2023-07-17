import Foundation

public struct ScriptNumber: Equatable {

    public static let zero = Self(unsafeValue: 0)
    public static let one = Self(unsafeValue: 1)
    public static let negativeOne = Self(unsafeValue: -1)
    
    private static let maxValue: Int = 0x0000007fffffffff
    private static let minValue: Int = -0x0000007fffffffff
    
    private var value: Int
    
    public init(_ value: Int) throws {
        guard value.magnitude <= Self.maxValue else {
            throw ScriptError.numberOverflow
        }
        self.value = value
    }
    public init(_ value: UInt8) {
        self.init(unsafeValue: Int(value))
    }
    
    public init(_ value: Bool) {
        self.init(unsafeValue: Int(value ? 1 : 0))
    }
    
    public init(_ data: Data) {
        if data.isEmpty {
            value = 0
            return
        }
        var data = data
        //guard data.count <= MemoryLayout<Int>.size - 3 else { return nil }
        let countLimit = MemoryLayout<Int>.size - 3 // 5 bytes
        if data.count > countLimit {
            data = data.dropLast(data.count - countLimit)
        }
        let negative = if let last = data.last { last & 0b10000000 != 0 } else { false }
        data[data.endIndex - 1] &= 0b01111111 // We make it positive
        let padded = data + Data(repeating: 0, count: MemoryLayout<Int>.size - data.count)
        let magnitude = padded.withUnsafeBytes { $0.loadUnaligned(as: Int.self) }
        value = (negative ? -1 : 1) * magnitude
    }

    private init(unsafeValue value: Int) {
        self.value = value
    }
    
    public static func isFalse(_ data: Data) -> Bool {
        data == Self.zero.data
    }

    public static func isTrue(_ data: Data) -> Bool {
        data == Self.one.data
    }

    public var data: Data {
        if value == 0 {
            return Data()
        }
        let magnitude = value.magnitude
        if magnitude < Int(pow(Double(2), 8 * 1 - 1)) {
            let signMask = UInt8(isNegative ? 0b10000000 : 0)
            let withSign = UInt8(magnitude) | signMask
            return withUnsafeBytes(of: withSign) { Data($0) }
        }
        if magnitude < Int(pow(Double(2), 8 * 2 - 1)) {
            let signMask = UInt16(isNegative ? 0x8000 : 0)
            let withSign = UInt16(magnitude) | signMask
            return withUnsafeBytes(of: withSign) { Data($0) }
        }
        if magnitude < Int(pow(Double(2), 8 * 3 - 1)) {
            let signMask = UInt32(isNegative ? 0x00800000 : 0)
            let withSign = UInt32(magnitude) | signMask
            var data = withUnsafeBytes(of: withSign) { Data($0) }
            data = data.dropLast(MemoryLayout<UInt32>.size - 3)
            return data
        }
        if magnitude < Int(pow(Double(2), 8 * 4 - 1)) {
            let signMask = UInt32(isNegative ? 0x80000000 : 0)
            let withSign = UInt32(magnitude) | signMask
            return withUnsafeBytes(of: withSign) { Data($0) }
        }
        if magnitude <= Self.maxValue {
            let signMask = UInt(isNegative ? 0x0000008000000000 : 0)
            let withSign = UInt(magnitude) | signMask
            var data = withUnsafeBytes(of: withSign) { Data($0) }
            data = data.dropLast(MemoryLayout<UInt>.size - 5)
            return data
        }
        fatalError() // Should never reach here
    }
    
    public var dataCount: Int {
        if value == 0 {
            return 0
        }
        let magnitude = value.magnitude
        if magnitude < Int(pow(Double(2), 8 * 1 - 1)) {
            return 1
        }
        if magnitude < Int(pow(Double(2), 8 * 2 - 1)) {
            return 2
        }
        if magnitude < Int(pow(Double(2), 8 * 3 - 1)) {
            return 3
        }
        if magnitude < Int(pow(Double(2), 8 * 4 - 1)) {
            return 4
        }
        if magnitude <= Self.maxValue {
            return 5
        }
        fatalError() // Should never reach here
    }

    public var asInt: Int {
        value
    }

    private var isNegative: Bool {
        value.signum() == -1
    }

    public mutating func add(_ b: ScriptNumber) throws {
        let newValue = value + b.value
        if newValue.magnitude > Self.maxValue {
            throw ScriptError.numberOverflow
        }
        value = newValue
    }
    
    public mutating func negate() {
        value = -value
    }
}
