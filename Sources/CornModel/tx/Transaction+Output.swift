import Foundation

extension Transaction {
    
    public struct Output: Equatable {

        init(value: Amount, scriptData: Data) {
            self.value = value
            self.scriptData = scriptData
        }
        
        /// Amount in satoshis.
        var value: Amount
        
        /// Raw content of scriptPubKey. It may contain an invalid / unparsable script.
        var scriptData: Data
    }
}

extension Transaction.Output {

    public init(value: Amount, scriptPubKey: [Op]) {
        self.init(value: value, scriptData: scriptPubKey.data)
    }
        
    init(_ data: Data) {
        var data = data
        let value = data.withUnsafeBytes { $0.loadUnaligned(as: Amount.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: value))
        let scriptData = Data(varLenData: data)
        self.init(value: value, scriptData: scriptData)
    }

    var data: Data {
        var ret = Data()
        ret += valueData
        ret += scriptData.varLenData
        return ret
    }

    var valueData: Data {
        withUnsafeBytes(of: value) { Data($0) }
    }

    var script: [Op] {
        [Op](scriptData)
    }
    
    var doubleValue: Double {
        Double(value) / 100_000_000
    }
    
    func address(network: Network = .main) -> String {
        if script.scriptType == .witnessV0KeyHash || script.scriptType == .witnessV0ScriptHash {
            return (try? SegwitAddrCoder(bech32m: false).encode(hrp: network.bech32HRP, version: 0, program: script.witnessProgram)) ?? ""
        } else if script.scriptType == .witnessV1TapRoot {
            return (try? SegwitAddrCoder(bech32m: true).encode(hrp: network.bech32HRP, version: 1, program: script.witnessProgram)) ?? ""
        }
        return ""
    }
    
    var dataLen: Int {
        MemoryLayout.size(ofValue: value) + scriptData.varLenSize
    }
}
