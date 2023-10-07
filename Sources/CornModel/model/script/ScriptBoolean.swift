import Foundation

public struct ScriptBoolean: Equatable {

    public static let `false` = Self(false)
    public static let `true` = Self(true)
    
    public let value: Bool
    
    public init(_ value: Bool) {
        self.value = value
    }
    
    public init(minimalData: Data) throws {
        if minimalData == Data() {
            value = false
        } else if minimalData == Data([1]) {
            value = true
        } else {
            throw ScriptError.nonMinimalBoolean
        }
    }
    
    public init(_ data: Data) {
        let firstNonZeroIndex = data.firstIndex { $0 != 0 }
        if firstNonZeroIndex == data.endIndex - 1, let last = data.last, last == 0x80 {
            // Negative zero
            value = false
        } else {
            value = firstNonZeroIndex != .none
        }
    }

    public var data: Data {
        value ? Data([1]) : Data()
    }
    
    public var size: Int {
        value ? 1 : 0
    }
    
    public func and(_ b: ScriptBoolean) -> ScriptBoolean {
        Self(value && b.value)
    }
}
