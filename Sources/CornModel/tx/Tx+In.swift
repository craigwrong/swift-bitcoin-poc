import Foundation

public extension Tx {
    
    struct In: Equatable {
        public let txID: String // 32 bytes hex
        public let outIdx: UInt32 // Index of vout
        public var sequence: UInt32 // Index of vout
        public var scriptSig: ScriptLegacy
        public var witness: [Data]?

        public init(txID: String, outIdx: UInt32, sequence: UInt32, scriptSig: ScriptLegacy, witness: [Data]? = .none) {
            self.txID = txID
            self.outIdx = outIdx
            self.sequence = sequence
            self.scriptSig = scriptSig
            self.witness = witness
        }
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
        
        let scriptSigData = Data(varLenData: data[offset...])
        let scriptSig = ScriptLegacy(scriptSigData)
        offset += scriptSigData.varLenSize
        
        let sequenceData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let sequence = sequenceData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        offset += sequenceData.count
        
        self.init(txID: txID, outIdx: outIdx, sequence: sequence, scriptSig: scriptSig)
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
        return txIDData + outputData + scriptSig.data.varLenData + sequenceData
    }

    var witnessData: Data {
        var ret = Data()
        ret += Data(varInt: UInt64(witness?.count ?? 0))
        if let witness {
            ret += witness.reduce(Data()) { $0 + $1.varLenData }
        }
        return ret
    }

    var witnessMemSize: Int {
        UInt64(witness?.count ?? 0).varIntSize + (witness?.varLenSize ?? 0)
    }

    mutating func populateWitness(from data: Data) {
        var data = data
        let witnessLen = data.varInt
        data = data.dropFirst(witnessLen.varIntSize)
        var witness = [Data]()
        for _ in 0 ..< witnessLen {
            let element = Data(varLenData: data)
            witness.append(element)
            data = data.dropFirst(element.varLenSize)
        }
        self.witness = witness
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
