import Foundation

extension Transaction {
    
    public struct Input: Equatable {
        public var txID: String
        public var outIdx: Int
        public var sequence: Sequence
        public var script: Script?
        public var witness: [Data]?
        
        public init(txID: String, outIdx: Int, sequence: Sequence, script: Script? = .none, witness: [Data]? = .none) {
            self.txID = txID
            self.outIdx = outIdx
            self.sequence = sequence
            self.script = script
            self.witness = witness
        }
    }
}

extension Transaction.Input {
    
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
        
        let scriptData = Data(varLenData: data[offset...])
        let script = Script(scriptData)
        offset += scriptData.varLenSize
        
        guard let sequenceData = Sequence(data[offset...]) else {
            fatalError()
        }
        offset += Sequence.dataCount
        
        self.init(txID: txID, outIdx: outIdx, sequence: sequenceData, script: script)
    }
    
    var isCoinbase: Bool { txID == Transaction.coinbaseID }
    
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
        if let script {
            ret += script.data.varLenData
        }
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
    
    var sequenceData: Data { sequence.data }
    
    var dataLen: Int {
        txID.count / 2 + MemoryLayout.size(ofValue: UInt32(outIdx)) + (script?.dataLen ?? 0) + Sequence.dataCount
    }
    
    var witnessDataLen: Int {
        UInt64(witness?.count ?? 0).varIntSize + (witness?.varLenSize ?? 0)
    }
    
    var taprootAnnex: Data? {
        // If there are at least two witness elements, and the first byte of the last element is 0x50, this last element is called annex a
        if let witness, witness.count > 1, let maybeAnnex = witness.last, let firstElem = maybeAnnex.first, firstElem == 0x50 {
            return maybeAnnex
        } else {
            return .none
        }
    }
}
