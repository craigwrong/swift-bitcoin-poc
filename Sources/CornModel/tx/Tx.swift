import Foundation
import CryptoKit
import ECCHelper

/// A bitcoin transaction. Could be a partial or invalid transaction.
public struct Tx: Equatable {
    
    /// Creates a final or partial transaction.
    /// - Parameters:
    ///   - version: The bitcoin transaction version.
    ///   - lockTime: The lock time raw integer value.
    ///   - ins: The transaction's inputs.
    ///   - outs: The transaction's outputs.
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
    
    static let empty = Self(version: .v1, lockTime: 0, ins: [], outs: [])
    static let coinbaseID = String(repeating: "0", count: 64)
    
    init(_ data: Data) {
        var data = data
        let version = Version(data)
        data = data.dropFirst(version.dataLen)
        
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
            data = data.dropFirst(input.dataLen)
        }
        
        let outsLen = data.varInt
        data = data.dropFirst(outsLen.varIntSize)
        
        var outs = [Out]()
        for _ in 0 ..< outsLen {
            let out = Out(data)
            outs.append(out)
            data = data.dropFirst(out.dataLen)
        }
        
        if isSegwit {
            for i in ins.indices {
                ins[i].populateWitness(from: data)
                data = data.dropFirst(ins[i].witnessDataLen)
            }
        }
        
        let lockTime = data.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)
        
        self.init(version: version, lockTime: lockTime, ins: ins, outs: outs)
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
        var ret = Data()
        ret += version.data
        ret += Data(varInt: insLen)
        ret += ins.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outsLen)
        ret += outs.reduce(Data()) { $0 + $1.data }
        ret += withUnsafeBytes(of: lockTime) { Data($0) }
        return ret
    }
    
    var size: Int { nonWitnessSize + witnessSize }
    var weight: Int { nonWitnessSize * 4 + witnessSize }
    var vsize: Int { Int((Double(weight) / 4).rounded(.up)) }
    var txid: String { hash256(idData).reversed().hex }
    var wtxid: String { hash256(data).reversed().hex}
    
    /// Whether this is the coinbase transaction of any given block. Based of whether the first and only input is a coinbase input.
    var isCoinbase: Bool { ins.first?.isCoinbase ?? false }
    var hasWitness: Bool { ins.contains { $0.witness != .none } }
    var insLen: UInt64 { .init(ins.count) }
    var outsLen: UInt64 { .init(outs.count) }
    
    var nonWitnessSize: Int {
        version.dataLen + insLen.varIntSize + ins.reduce(0) { $0 + $1.dataLen } + outsLen.varIntSize + outs.reduce(0) { $0 + $1.dataLen } + MemoryLayout.size(ofValue: lockTime)
    }
    
    var witnessSize: Int {
        hasWitness ? (MemoryLayout.size(ofValue: Tx.segwitMarker) + MemoryLayout.size(ofValue: Tx.segwitFlag)) + ins.reduce(0) { $0 + $1.witnessDataLen } : 0
    }
}

extension Tx: CustomStringConvertible {
    
    public var description: String { txid }
}
