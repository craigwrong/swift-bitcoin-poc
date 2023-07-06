import Foundation

extension Transaction { public struct Input: Equatable {

    public var outpoint: Outpoint
    public var sequence: Sequence
    public var script: Script
    public var witness: Witness?
    
    public init(outpoint: Outpoint, sequence: Sequence, script: Script = .empty, witness: Witness? = .none) {
        self.outpoint = outpoint
        self.sequence = sequence
        self.script = script
        self.witness = witness
    }

    init(_ data: Data) {
        var offset = data.startIndex
        let outpoint = Outpoint(data)
        offset += Outpoint.dataCount
        
        let scriptData = Data(varLenData: data[offset...])
        let script = Script(scriptData)
        offset += scriptData.varLenSize
        
        guard let sequenceData = Sequence(data[offset...]) else {
            fatalError()
        }
        offset += Sequence.dataCount
        
        self.init(outpoint: outpoint, sequence: sequenceData, script: script)
    }
    
    var isCoinbase: Bool { outpoint.transaction == Transaction.coinbaseID }
    
    var data: Data {
        var ret = Data()
        ret += outpoint.data
        ret += script.data.varLenData
        ret += sequence.data
        return ret
    }
    
    var dataCount: Int {
        Outpoint.dataCount + script.dataCount + Sequence.dataCount
    }

} }
