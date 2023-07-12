import Foundation
import CryptoKit
import ECCHelper

/// A bitcoin transaction. Could be a partial or invalid transaction.
public struct Transaction: Equatable {

    // Transaction ID length in bytes.
    static let identifierDataCount = 32

    /// Its presence withn transaction data indicates the inclusion of seggregated witness (SegWit) data.
    static let segwitMarker = UInt8(0x00)
    
    /// Its presence withn transaction data indicates the number of witness sections present. At the time of writing only one possible witness data section may exist.
    static let segwitFlag = UInt8(0x01)

    static let empty = Self(version: .v1, locktime: .disabled, inputs: [], outputs: [])
    static let coinbaseID = String(repeating: "0", count: Transaction.identifierDataCount * 2)

    /// The transaction format version.
    public var version: Version
    
    /// Transaction lock time.
    public var locktime: Locktime

    /// Transaction inputs.
    public var inputs: [Input]
    
    /// Transaction outputs.
    public var outputs: [Output]
    
    /// Creates a final or partial transaction.
    /// - Parameters:
    ///   - version: The bitcoin transaction version.
    ///   - locktime: The lock time raw integer value.
    ///   - inputs: The transaction's inputs.
    ///   - outputs: The transaction's outputs.
    public init(version: Transaction.Version, locktime: Locktime, inputs: [Transaction.Input], outputs: [Transaction.Output]) {
        self.version = version
        self.locktime = locktime
        self.inputs = inputs
        self.outputs = outputs
    }

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
        
        let inputsCount = data.varInt
        data = data.dropFirst(inputsCount.varIntSize)
        
        var inputs = [Input]()
        for _ in 0 ..< inputsCount {
            let input = Input(data)
            inputs.append(input)
            data = data.dropFirst(input.dataCount)
        }
        
        let outputsCount = data.varInt
        data = data.dropFirst(outputsCount.varIntSize)
        
        var outputs = [Output]()
        for _ in 0 ..< outputsCount {
            let out = Output(data)
            outputs.append(out)
            data = data.dropFirst(out.dataCount)
        }
        
        if isSegwit {
            for i in inputs.indices {
                let witness = Input.Witness(data)
                inputs[i].witness = witness
                data = data.dropFirst(witness.dataCount)
            }
        }
        
        guard let locktime = Locktime(data) else {
            fatalError()
        }
        data = data.dropFirst(Locktime.dataCount)
        
        self.init(version: version, locktime: locktime, inputs: inputs, outputs: outputs)
    }
    
    var data: Data {
        var ret = Data()
        ret += version.data
        if hasWitness {
            ret += Data([Transaction.segwitMarker, Transaction.segwitFlag])
        }
        ret += Data(varInt: inputsCount)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outputsCount)
        ret += outputs.reduce(Data()) { $0 + $1.data }
        if hasWitness {
            ret += inputs.reduce(Data()) {
                guard let witness = $1.witness else {
                    return $0
                }
                return $0 + witness.data
            }
        }
        ret += locktime.data
        return ret
    }
    
    var idData: Data {
        var ret = Data()
        ret += version.data
        ret += Data(varInt: inputsCount)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outputsCount)
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
    private var inputsCount: UInt64 { .init(inputs.count) }
    private var outputsCount: UInt64 { .init(outputs.count) }
    
    var nonWitnessSize: Int {
        Version.dataCount + inputsCount.varIntSize + inputs.reduce(0) { $0 + $1.dataCount } + outputsCount.varIntSize + outputs.reduce(0) { $0 + $1.dataCount } + Locktime.dataCount
    }
    
    var witnessSize: Int {
        hasWitness ? (MemoryLayout.size(ofValue: Transaction.segwitMarker) + MemoryLayout.size(ofValue: Transaction.segwitFlag)) + inputs.reduce(0) { $0 + ($1.witness?.dataCount ?? 0) } : 0
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
