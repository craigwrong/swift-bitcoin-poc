import Foundation

extension Transaction { public struct Output: Equatable {
    
    init(value: Amount, script: Data) {
        self.value = value
        self.script = script
    }
    
    /// Amount in satoshis.
    var value: Amount
    
    /// Raw content of scriptPubKey. It may contain an invalid / unparsable script.
    var script: Data
    
    public init(value: Amount, script: Script) {
        self.init(value: value, script: script.data)
    }
    
    init(_ data: Data) {
        var data = data
        let value = data.withUnsafeBytes { $0.loadUnaligned(as: Amount.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: value))
        let scriptData = Data(varLenData: data)
        self.init(value: value, script: scriptData)
    }
    
    var data: Data {
        var ret = Data()
        ret += valueData
        ret += script.varLenData
        return ret
    }
    
    var valueData: Data {
        withUnsafeBytes(of: value) { Data($0) }
    }

    var dataCount: Int {
        MemoryLayout.size(ofValue: value) + script.varLenSize
    }
} }
