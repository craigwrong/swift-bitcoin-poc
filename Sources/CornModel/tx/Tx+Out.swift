import Foundation

public extension Tx {
    
    struct Out: Equatable {
        public init(value: UInt64, scriptPubKeyData: Data) {
            self.value = value
            self.scriptPubKeyData = scriptPubKeyData
        }
        
        public let value: UInt64 // Sats
        public let scriptPubKeyData: Data
    }
}

extension Tx.Out {
    var memSize: Int {
        MemoryLayout.size(ofValue: value) + scriptPubKeyData.varLenSize
    }
}

public extension Tx.Out {

    var scriptPubKey: ScriptLegacy {
        ScriptLegacy(scriptPubKeyData)
    }
    
    var doubleValue: Double {
        Double(value) / 100_000_000
    }

    var data: Data {
        return valueData + scriptPubKeyData.varLenData
    }

    var valueData: Data {
        withUnsafeBytes(of: value) { Data($0) }
    }
    
    func address(network: Network = .main) -> String {
        if scriptPubKey.scriptType == .witnessV0KeyHash || scriptPubKey.scriptType == .witnessV0ScriptHash {
            return (try? SegwitAddrCoder(bech32m: false).encode(hrp: network.bech32HRP, version: 0, program: scriptPubKey.witnessProgram)) ?? ""
        } else if scriptPubKey.scriptType == .witnessV1TapRoot {
            return (try? SegwitAddrCoder(bech32m: true).encode(hrp: network.bech32HRP, version: 1, program: scriptPubKey.witnessProgram)) ?? ""
        }
        return ""
    }
    
    init(_ data: Data) {
        var data = data
        let value = data.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: value))
        let scriptPubKeyData = Data(varLenData: data)
        self.init(value: value, scriptPubKeyData: scriptPubKeyData)
    }
}
