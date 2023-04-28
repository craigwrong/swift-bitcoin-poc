import Foundation
import CryptoKit
import ECCHelper

public struct Tx: Equatable {
    public static func == (lhs: Tx, rhs: Tx) -> Bool {
        lhs.version == rhs.version && lhs.ins == rhs.ins && lhs.outs == rhs.outs && lhs.witnessData == rhs.witnessData && lhs.lockTime == rhs.lockTime
    }
    

    public struct SigMsgV1Cache {
        public internal(set) var shaPrevouts: Data?
        public internal(set) var shaPrevoutsUsed: Bool = false
        public internal(set) var shaAmounts: Data?
        public internal(set) var shaAmountsUsed: Bool = false
        public internal(set) var shaScriptPubKeys: Data?
        public internal(set) var shaScriptPubKeysUsed: Bool = false
        public internal(set) var shaSequences: Data?
        public internal(set) var shaSequencesUsed: Bool = false
        public internal(set) var shaOuts: Data?
        public internal(set) var shaOutsUsed: Bool = false
    }

    public internal(set) var sigMsgV1Cache = SigMsgV1Cache?.none

    public init(version: Tx.Version, ins: [Tx.In], outs: [Tx.Out], witnessData: [Tx.Witness], lockTime: UInt32) {
        self.version = version
        self.ins = ins
        self.outs = outs
        self.witnessData = witnessData
        self.lockTime = lockTime
    }
    
    /// Its presence withn transaction data indicates the inclusion of seggregated witness (SegWit) data.
    static let segwitMarker = UInt8(0x00)
    
    /// Its presence withn transaction data indicates the number of witness sections present. At the time of writing only one possible witness data section may exist.
    static let segwitFlag = UInt8(0x01)

    /// The transaction format version.
    public var version: Version

    /// Transaction inputs.
    public var ins: [In]
    
    /// Transaction outputs.
    public var outs: [Out]
    
    /// Witness data. When not empty, it contains the same number of elements as ther are inputs in the transaction.
    public var witnessData: [Witness]
    
    /// Transaction lock time.
    public var lockTime: UInt32
}

extension Tx: CustomStringConvertible {
    
    public var description: String {
        txid
    }
}

public extension Tx {
    /// Whether this is the coinbase transaction of any given block. Based of whether the first and only input is a coinbase input.
    var isCoinbase: Bool {
        ins.first?.isCoinbase ?? false
    }
    
    var data: Data {
        let markerAndFlagData: Data
        if witnessData.count == ins.count {
            markerAndFlagData = Data([Tx.segwitMarker, Tx.segwitFlag])
        } else {
            markerAndFlagData = Data()
        }
        
        let insLenData = Data(varInt: insLen)
        let inputsData = ins.reduce(Data()) { $0 + $1.data }
        
        let outsLenData = Data(varInt: outsLen)
        let outsData = outs.reduce(Data()) { $0 + $1.data }
        
        let witnessesData = witnessData.reduce(Data()) { $0 + $1.data }
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }

        return version.data + markerAndFlagData + insLenData + inputsData + outsLenData + outsData + witnessesData + lockTimeData
    }
    
    var idData: Data {
        let insLenData = Data(varInt: insLen)
        let inputsData = ins.reduce(Data()) { $0 + $1.data }
        
        let outsLenData = Data(varInt: outsLen)
        let outsData = outs.reduce(Data()) { $0 + $1.data }
        
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }

        return version.data + insLenData + inputsData + outsLenData + outsData + lockTimeData
    }

    init(_ data: Data) {
        var data = data
        guard let version = Version(data) else {
            fatalError("Unknown bitcoin transaction version.")
        }
        data = data.dropFirst(version.dataSize)

        // Check for marker and segwit flag
        let maybeSegwitMarker = data[data.startIndex]
        let maybeSegwitFlag = data[data.startIndex + 1]
        let isSegwit: Bool
        if maybeSegwitMarker == Tx.segwitMarker && maybeSegwitFlag == Tx.segwitFlag {
            isSegwit = true
            data = data.dropFirst(2)
        } else {
            isSegwit = false
        }
        
        let insLen = data.varInt
        data = data.dropFirst(insLen.varIntSize)
        
        var ins = [In]()
        for _ in 0 ..< insLen {
            let input = In(data)
            ins.append(input)
            data = data.dropFirst(input.memSize)
        }

        let outsLen = data.varInt
        data = data.dropFirst(outsLen.varIntSize)
        
        var outs = [Out]()
        for _ in 0 ..< outsLen {
            let out = Out(data)
            outs.append(out)
            data = data.dropFirst(out.memSize)
        }

        var witnesses = [Witness]()
        if isSegwit {
            for _ in 0 ..< insLen {
                let witness = Witness(data)
                witnesses.append(witness)
                data = data.dropFirst(witness.memSize)
            }
        }

        let lockTime = data.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)
        
        self.init(version: version, ins: ins, outs: outs, witnessData: witnesses, lockTime: lockTime)
    }

    var size: Int {
        nonWitnessSize + witnessSize
    }

    var weight: Int {
        nonWitnessSize * 4 + witnessSize
    }
    
    var vsize: Int {
        Int((Double(weight) / 4).rounded(.up))
    }
    
    var txid: String {
        hash256(idData).reversed().hex
    }

    var wtxid: String {
        hash256(data).reversed().hex
    }
}

extension Tx {
    var insLen: UInt64 {
        .init(ins.count)
    }

    var outsLen: UInt64 {
        .init(outs.count)
    }

    var nonWitnessSize: Int {
        version.dataSize + insLen.varIntSize + ins.reduce(0) { $0 + $1.memSize } + outsLen.varIntSize + outs.reduce(0) { $0 + $1.memSize } + MemoryLayout.size(ofValue: lockTime)
    }
    
    var witnessSize: Int {
        (witnessData.isEmpty ? 0 : (MemoryLayout.size(ofValue: Tx.segwitMarker) + MemoryLayout.size(ofValue: Tx.segwitFlag))) + witnessData.reduce(0) { $0 + $1.memSize }
    }
}
