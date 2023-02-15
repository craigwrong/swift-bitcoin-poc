import Foundation

public extension Tx {
    struct In: Equatable {
        public var txID: String // 32 bytes hex
        public var output: UInt32 // Index of vout
        public var scriptSig: Script
        public var sequence: UInt32 // Index of vout
    }
}

extension Tx.In {
    var memSize: Int {
        txID.count / 2 + MemoryLayout.size(ofValue: output) + scriptSig.memSize +  MemoryLayout.size(ofValue: sequence)
    }
}

public extension Tx.In {

    var isCoinbase: Bool {
        txID == String(repeating: "0", count: 64)
    }

    var data: Data {
        let txIDData = Data(hex: txID).reversed()
        let outputData = withUnsafeBytes(of: output) { Data($0) }
        return txIDData + outputData + scriptSig.data() + sequenceData
    }
    
    var prevoutData: Data {
        let txIDData = Data(hex: txID).reversed()
        let outputData = withUnsafeBytes(of: output) { Data($0) }
        return txIDData + outputData
    }
    
    var sequenceData: Data {
        withUnsafeBytes(of: sequence) { Data($0) }
    }
    
    init(_ data: Data) {
        var offset = data.startIndex
        let txIDData = Data(data[offset ..< offset + 32].reversed())
        let txID = txIDData.hex
        offset += txIDData.count

        let outputData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let output = outputData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        offset += outputData.count

        let scriptSig = Script(data[offset...])
        offset += scriptSig.memSize
        
        let sequenceData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let sequence = sequenceData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        offset += sequenceData.count

        self.init(txID: txID, output: output, scriptSig: scriptSig, sequence: sequence)
    }
}
