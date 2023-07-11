import Foundation

extension Transaction { public struct Output: Equatable {
    
    init(value: Amount, script: SerializedScript) {
        self.value = value
        self.script = script
    }
    
    /// Amount in satoshis.
    var value: Amount
    
    /// Raw content of scriptPubKey. It may contain an invalid / unparsable script.
    var script: SerializedScript
    
    public init(value: Amount, script: ParsedScript) {
        self.init(value: value, script: .init(script.data))
    }
    
    init(_ data: Data) {
        var data = data
        let value = data.withUnsafeBytes { $0.loadUnaligned(as: Amount.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: value))
        let script = SerializedScript(prefixedData: data)
        self.init(value: value, script: script)
    }
    
    var data: Data {
        var ret = Data()
        ret += valueData
        ret += script.prefixedData
        return ret
    }
    
    var valueData: Data {
        withUnsafeBytes(of: value) { Data($0) }
    }

    var dataCount: Int {
        MemoryLayout.size(ofValue: value) + script.prefixedDataCount
    }
} }
