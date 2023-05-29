import Foundation

public extension Tx {
    
    struct In: Equatable {
        public let txID: String
        public let outIdx: Int
        public var sequence: UInt32
        public var scriptSig: ScriptLegacy
        public var witness: [Data]?
        
        public init(txID: String, outIdx: Int, sequence: UInt32, scriptSig: ScriptLegacy, witness: [Data]? = .none) {
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
        let outIdx = Int(outIdxData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        })
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
    
    var data: Data {
        var ret = Data()
        ret += Data(hex: txID).reversed()
        ret += withUnsafeBytes(of: UInt32(outIdx)) { Data($0) }
        ret += scriptSig.data.varLenData
        ret += sequenceData
        return ret
    }
    
    var witnessData: Data {
        var ret = Data()
        ret += Data(varInt: UInt64(witness?.count ?? 0))
        if let witness {
            ret += witness.reduce(Data()) { $0 + $1.varLenData }
        }
        return ret
    }
    
    var prevoutData: Data {
        var ret = Data()
        ret += Data(hex: txID).reversed()
        ret += withUnsafeBytes(of: UInt32(outIdx)) { Data($0) }
        return ret
    }
    
    var sequenceData: Data {
        withUnsafeBytes(of: sequence) { Data($0) }
    }
    
    var dataLen: Int {
        txID.count / 2 + MemoryLayout.size(ofValue: UInt32(outIdx)) + scriptSig.dataLen +  MemoryLayout.size(ofValue: sequence)
    }
    
    var witnessDataLen: Int {
        UInt64(witness?.count ?? 0).varIntSize + (witness?.varLenSize ?? 0)
    }
}
