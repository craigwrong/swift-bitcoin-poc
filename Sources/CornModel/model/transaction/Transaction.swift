import Foundation

/// A bitcoin transaction. Could be a partial or invalid transaction.
public struct Transaction: Equatable {

    // Transaction ID length in bytes.
    static let idSize = 32

    /// Its presence withn transaction data indicates the inclusion of seggregated witness (SegWit) data.
    private static let segwitMarker = UInt8(0x00)
    
    /// Its presence withn transaction data indicates the number of witness sections present. At the time of writing only one possible witness data section may exist.
    private static let segwitFlag = UInt8(0x01)

    public static let empty = Self(version: .v1, locktime: .disabled, inputs: [], outputs: [])
    static let coinbaseID = String(repeating: "0", count: Transaction.idSize * 2)

    /// The transaction format version.
    public let version: Version
    
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
    public init(version: Version, locktime: Locktime, inputs: [Input], outputs: [Output]) {
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
        data = data.dropFirst(Version.size)
        
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
            data = data.dropFirst(input.size)
        }
        
        let outputsCount = data.varInt
        data = data.dropFirst(outputsCount.varIntSize)
        
        var outputs = [Output]()
        for _ in 0 ..< outputsCount {
            let out = Output(data)
            outputs.append(out)
            data = data.dropFirst(out.size)
        }
        
        if isSegwit {
            for i in inputs.indices {
                let witness = Witness(data)
                inputs[i].witness = witness
                data = data.dropFirst(witness.size)
            }
        }
        
        guard let locktime = Locktime(data) else {
            fatalError()
        }
        data = data.dropFirst(Locktime.size)
        
        self.init(version: version, locktime: locktime, inputs: inputs, outputs: outputs)
    }
    
    var data: Data {
        var ret = Data()
        ret += version.data
        if hasWitness {
            ret += Data([Transaction.segwitMarker, Transaction.segwitFlag])
        }
        ret += Data(varInt: inputsUInt64)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outputsUInt64)
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
        ret += Data(varInt: inputsUInt64)
        ret += inputs.reduce(Data()) { $0 + $1.data }
        ret += Data(varInt: outputsUInt64)
        ret += outputs.reduce(Data()) { $0 + $1.data }
        ret += locktime.data
        return ret
    }
    
    var size: Int { nonWitnessSize + witnessSize }
    var weight: Int { nonWitnessSize * 4 + witnessSize }
    var virtualSize: Int { Int((Double(weight) / 4).rounded(.up)) }
    var id: String { hash256(idData).reversed().hex }
    var witnessID: String { hash256(data).reversed().hex}
    
    /// Whether this is the coinbase transaction of any given block. Based of whether the first and only input is a coinbase input.
    var isCoinbase: Bool { inputs.first?.isCoinbase ?? false }
    var hasWitness: Bool { inputs.contains { $0.witness != .none } }
    private var inputsUInt64: UInt64 { .init(inputs.count) }
    private var outputsUInt64: UInt64 { .init(outputs.count) }
    
    var nonWitnessSize: Int {
        Version.size + inputsUInt64.varIntSize + inputs.reduce(0) { $0 + $1.size } + outputsUInt64.varIntSize + outputs.reduce(0) { $0 + $1.size } + Locktime.size
    }
    
    var witnessSize: Int {
        hasWitness ? (MemoryLayout.size(ofValue: Transaction.segwitMarker) + MemoryLayout.size(ofValue: Transaction.segwitFlag)) + inputs.reduce(0) { $0 + ($1.witness?.size ?? 0) } : 0
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
