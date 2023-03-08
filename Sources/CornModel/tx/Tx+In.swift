import Foundation

public extension Tx {
    
    struct In: Equatable {
        
        public var txID: String // 32 bytes hex
        public var outIdx: UInt32 // Index of vout
        public var scriptSig: Script
        public var sequence: UInt32 // Index of vout
    }
}

public extension Tx.In {
    
    init(_ data: Data) {
        var offset = data.startIndex
        let txIDData = Data(data[offset ..< offset + 32].reversed())
        let txID = txIDData.hex
        offset += txIDData.count
        
        let outIdxData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let outIdx = outIdxData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        offset += outIdxData.count
        
        let scriptSig = Script(data[offset...])
        offset += scriptSig.memSize
        
        let sequenceData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let sequence = sequenceData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        offset += sequenceData.count
        
        self.init(txID: txID, outIdx: outIdx, scriptSig: scriptSig, sequence: sequence)
    }
    
    var isCoinbase: Bool {
        txID == String(repeating: "0", count: 64)
    }
}

extension Tx.In {
    
    var memSize: Int {
        txID.count / 2 + MemoryLayout.size(ofValue: outIdx) + scriptSig.memSize +  MemoryLayout.size(ofValue: sequence)
    }
    
    var data: Data {
        let txIDData = Data(hex: txID).reversed()
        let outputData = withUnsafeBytes(of: outIdx) { Data($0) }
        return txIDData + outputData + scriptSig.data() + sequenceData
    }

    var prevoutData: Data {
        let txIDData = Data(hex: txID).reversed()
        let outputData = withUnsafeBytes(of: outIdx) { Data($0) }
        return txIDData + outputData
    }

    var sequenceData: Data {
        withUnsafeBytes(of: sequence) { Data($0) }
    }
}
