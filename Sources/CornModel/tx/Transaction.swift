import Foundation
import CryptoKit
import ECCHelper

public typealias Amount = UInt

/// A bitcoin transaction. Could be a partial or invalid transaction.
public struct Transaction: Equatable {

    public struct Locktime: Equatable {
        public static let disabled = Self(0)
        public static let maxBlock = Self(minClock.locktimeValue - 1)
        public static let minClock = Self(500_000_000)
        public static let maxClock = Self(Int(UInt32.max))

        public init?(blockHeight: Int) {
            guard blockHeight >= Self.disabled.locktimeValue && blockHeight <= Self.maxBlock.locktimeValue else {
                return nil
            }
            self.init(blockHeight)
        }
        
        public init?(secondsSince1970: Int) {
            guard secondsSince1970 >= Self.minClock.locktimeValue && secondsSince1970 <= Self.maxClock.locktimeValue else {
                return nil
            }
            self.init(secondsSince1970)
        }
        
        public var isDisabled: Bool {
            locktimeValue == Self.disabled.locktimeValue
        }
        
        public var blockHeight: Int? {
            guard locktimeValue <= Self.maxBlock.locktimeValue else {
                return nil
            }
            return locktimeValue
        }
        
        public var secondsSince1970: Int? {
            guard locktimeValue >= Self.minClock.locktimeValue else {
                return nil
            }
            return locktimeValue
        }

        static var dataCount: Int {
            MemoryLayout<UInt32>.size
        }

        init?(_ data: Data) {
            guard data.count >= Self.dataCount else {
                return nil
            }
            let value32 = data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
            self.init(value32)
        }
        
        init(_ rawValue: UInt32) {
            self.init(Int(rawValue))
        }
        
        var data: Data {
            withUnsafeBytes(of: rawValue) { Data($0) }
        }

        var rawValue: UInt32 {
            UInt32(locktimeValue)
        }

        private init(_ locktimeValue: Int) {
            self.locktimeValue = locktimeValue
        }
        
        private let locktimeValue: Int
    }
        
    /// Creates a final or partial transaction.
    /// - Parameters:
    ///   - version: The bitcoin transaction version.
    ///   - locktime: The lock time raw integer value.
    ///   - ins: The transaction's inputs.
    ///   - outs: The transaction's outputs.
    public init(version: Transaction.Version, locktime: Locktime, inputs: [Transaction.Input], outputs: [Transaction.Output]) {
        self.version = version
        self.locktime = locktime
        self.inputs = inputs
        self.outputs = outputs
    }
    
    /// Its presence withn transaction data indicates the inclusion of seggregated witness (SegWit) data.
    static let segwitMarker = UInt8(0x00)
    
    /// Its presence withn transaction data indicates the number of witness sections present. At the time of writing only one possible witness data section may exist.
    static let segwitFlag = UInt8(0x01)
    
    /// The transaction format version.
    public var version: Version
    
        /// Transaction lock time.
    public var locktime: Locktime

    /// Transaction inputs.
    public var inputs: [Input]
    
    /// Transaction outputs.
    public var outputs: [Output]
    
    static let empty = Self(version: .v1, locktime: .disabled, inputs: [], outputs: [])
    static let coinbaseID = String(repeating: "0", count: 64)
    
    init(_ data: Data) {
        var data = data
        guard let version = Version(data) else {
            fatalError()
        }
        data = data.dropFirst(Version.dataCount)
        
        // Check for marker and segwit flag
        let maybeSegwitMarker = data[data.startIndex]
        let maybeSegwitFlag = data[data.startIndex + 1]
        let isSegwit: Bool
        if maybeSegwitMarker == Transaction.segwitMarker && maybeSegwitFlag == Transaction.segwitFlag {
            isSegwit = true
            data = data.dropFirst(2)
        } else {
            isSegwit = false
        }
        
        let insLen = data.varInt
        data = data.dropFirst(insLen.varIntSize)
        
        var ins = [Input]()
        for _ in 0 ..< insLen {
            let input = Input(data)
            ins.append(input)
            data = data.dropFirst(input.dataLen)
        }
        
        let outsLen = data.varInt
        data = data.dropFirst(outsLen.varIntSize)
        
        var outs = [Output]()
        for _ in 0 ..< outsLen {
            let out = Output(data)
            outs.append(out)
            data = data.dropFirst(out.dataLen)
        }
        
        if isSegwit {
            for i in ins.indices {
                ins[i].populateWitness(from: data)
                data = data.dropFirst(ins[i].witnessDataLen)
            }
        }
        
        guard let locktime = Locktime(data) else {
            fatalError()
        }
        data = data.dropFirst(Locktime.dataCount)
        
        self.init(version: version, locktime: locktime, inputs: ins, outputs: outs)
    }
    
    var data: Data {
        var ret = Data()
        ret += version.data
        if hasWitness {
            ret += Data([Transaction.segwitMarker, Transaction.segwitFlag])
        }
        ret += Data(varInt: insLen)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outsLen)
        ret += outputs.reduce(Data()) { $0 + $1.data }
        if hasWitness {
            ret += inputs.reduce(Data()) { $0 + $1.witnessData }
        }
        ret += locktime.data
        return ret
    }
    
    var idData: Data {
        var ret = Data()
        ret += version.data
        ret += Data(varInt: insLen)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outsLen)
        ret += outputs.reduce(Data()) { $0 + $1.data }
        ret += locktime.data
        return ret
    }
    
    var size: Int { nonWitnessSize + witnessSize }
    var weight: Int { nonWitnessSize * 4 + witnessSize }
    var vsize: Int { Int((Double(weight) / 4).rounded(.up)) }
    var txid: String { hash256(idData).reversed().hex }
    var wtxid: String { hash256(data).reversed().hex}
    
    /// Whether this is the coinbase transaction of any given block. Based of whether the first and only input is a coinbase input.
    var isCoinbase: Bool { inputs.first?.isCoinbase ?? false }
    var hasWitness: Bool { inputs.contains { $0.witness != .none } }
    var insLen: UInt64 { .init(inputs.count) }
    var outsLen: UInt64 { .init(outputs.count) }
    
    var nonWitnessSize: Int {
        Version.dataCount + insLen.varIntSize + inputs.reduce(0) { $0 + $1.dataLen } + outsLen.varIntSize + outputs.reduce(0) { $0 + $1.dataLen } + Locktime.dataCount
    }
    
    var witnessSize: Int {
        hasWitness ? (MemoryLayout.size(ofValue: Transaction.segwitMarker) + MemoryLayout.size(ofValue: Transaction.segwitFlag)) + inputs.reduce(0) { $0 + $1.witnessDataLen } : 0
    }
    
    func isFinal(blockHeight: UInt32?, blockTime: Int64?) -> Bool {
        precondition((blockHeight == .none && blockTime != .none) || (blockHeight != .none && blockTime == .none))
        if locktime == .disabled { return true }

        if let blockHeight, let txBlockHeight = locktime.blockHeight, txBlockHeight < blockHeight {
            return true
        } else if let blockTime, let txBlockTime = locktime.secondsSince1970, txBlockTime < blockTime {
            return true
        }

        // Even if tx.nLockTime isn't satisfied by nBlockHeight/nBlockTime, a
        // transaction is still considered final if all inputs' nSequence ==
        // SEQUENCE_FINAL (0xffffffff), in which case nLockTime is ignored.
        //
        // Because of this behavior OP_CHECKLOCKTIMEVERIFY/CheckLockTime() will
        // also check that the spending input's nSequence != SEQUENCE_FINAL,
        // ensuring that an unsatisfied nLockTime value will actually cause
        // IsFinalTx() to return false here:
        return inputs.allSatisfy { $0.sequence == .final }
    }
}

extension Transaction: CustomStringConvertible {
    
    public var description: String { txid }
}