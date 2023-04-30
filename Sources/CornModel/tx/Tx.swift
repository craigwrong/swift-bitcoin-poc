import Foundation
import CryptoKit
import ECCHelper

public struct SigMsgV1Cache {
    public init(shaPrevouts: Data? = nil, shaPrevoutsUsed: Bool = false, shaAmounts: Data? = nil, shaAmountsUsed: Bool = false, shaScriptPubKeys: Data? = nil, shaScriptPubKeysUsed: Bool = false, shaSequences: Data? = nil, shaSequencesUsed: Bool = false, shaOuts: Data? = nil, shaOutsUsed: Bool = false) {
        self.shaPrevouts = shaPrevouts
        self.shaPrevoutsUsed = shaPrevoutsUsed
        self.shaAmounts = shaAmounts
        self.shaAmountsUsed = shaAmountsUsed
        self.shaScriptPubKeys = shaScriptPubKeys
        self.shaScriptPubKeysUsed = shaScriptPubKeysUsed
        self.shaSequences = shaSequences
        self.shaSequencesUsed = shaSequencesUsed
        self.shaOuts = shaOuts
        self.shaOutsUsed = shaOutsUsed
    }
    
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

public struct Tx: Equatable {

    public init(version: Tx.Version, lockTime: UInt32, ins: [Tx.In], outs: [Tx.Out]) {
        self.version = version
        self.lockTime = lockTime
        self.ins = ins
        self.outs = outs
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
    
    /// Transaction lock time.
    public var lockTime: UInt32
}

extension Tx: CustomStringConvertible {
    
    public var description: String {
        txid
    }
}

public extension Tx {

    static let empty = Self(version: .v1, lockTime: 0, ins: [], outs: [])
    
    /// Whether this is the coinbase transaction of any given block. Based of whether the first and only input is a coinbase input.
    var isCoinbase: Bool {
        ins.first?.isCoinbase ?? false
    }
    
    var data: Data {
        var ret = Data()
        ret += version.data
        if hasWitness {
            ret += Data([Tx.segwitMarker, Tx.segwitFlag])
        }
        ret += Data(varInt: insLen)
        ret += ins.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outsLen)
        ret += outs.reduce(Data()) { $0 + $1.data }
        if hasWitness {
            ret += ins.reduce(Data()) { $0 + $1.witnessData }
        }
        ret += withUnsafeBytes(of: lockTime) { Data($0) }
        return ret
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

        if isSegwit {
            for i in ins.indices {
                ins[i].populateWitness(from: data)
                data = data.dropFirst(ins[i].witnessMemSize)
            }
        }

        let lockTime = data.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)
        
        self.init(version: version, lockTime: lockTime, ins: ins, outs: outs)
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

    var hasWitness: Bool {
        ins.contains { $0.witness != .none }
    }

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
        hasWitness ? (MemoryLayout.size(ofValue: Tx.segwitMarker) + MemoryLayout.size(ofValue: Tx.segwitFlag)) + ins.reduce(0) { $0 + $1.witnessMemSize } : 0
    }
}
