import Foundation

extension Transaction { public struct Input: Equatable {

    public var outpoint: Outpoint
    public var sequence: Sequence
    public var script: SerializedScript
    public var witness: Witness?

    public init(outpoint: Outpoint, sequence: Sequence, script: ParsedScript, witness: Witness? = .none) {
        self.init(outpoint: outpoint, sequence: sequence, script: script.serialized, witness: witness)
    }

    public init(outpoint: Outpoint, sequence: Sequence, script: SerializedScript = .empty, witness: Witness? = .none) {
        self.outpoint = outpoint
        self.sequence = sequence
        self.script = script
        self.witness = witness
    }

    init(_ data: Data) {
        var offset = data.startIndex
        let outpoint = Outpoint(data)
        offset += Outpoint.dataCount
        
        let script = SerializedScript(prefixedData: data[offset...])
        offset += script.prefixedDataCount
        
        guard let sequence = Sequence(data[offset...]) else {
            fatalError()
        }
        offset += Sequence.dataCount
        
        self.init(outpoint: outpoint, sequence: sequence, script: script)
    }
    
    var isCoinbase: Bool { outpoint.transaction == Transaction.coinbaseID }
    
    var data: Data {
        var ret = Data()
        ret += outpoint.data
        ret += script.prefixedData
        ret += sequence.data
        return ret
    }
    
    var dataCount: Int {
        Outpoint.dataCount + script.prefixedDataCount + Sequence.dataCount
    }

} }
