import Foundation
import CryptoKit
import ECHelper

public struct Tx: Equatable {
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

extension Tx {
    var inCount: UInt64 {
        .init(ins.count)
    }

    var outCount: UInt64 {
        .init(outs.count)
    }

    var nonWitnessSize: Int {
        version.dataSize + inCount.varIntSize + ins.reduce(0) { $0 + $1.memSize } + outCount.varIntSize + outs.reduce(0) { $0 + $1.memSize } + MemoryLayout.size(ofValue: lockTime)
    }
    
    var witnessSize: Int {
        (witnessData.isEmpty ? 0 : (MemoryLayout.size(ofValue: Tx.segwitMarker) + MemoryLayout.size(ofValue: Tx.segwitFlag))) + witnessData.reduce(0) { $0 + $1.memSize }
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
        
        let inputsCountData = Data(varInt: inCount)
        let inputsData = ins.reduce(Data()) { $0 + $1.data }
        
        let outputsCountData = Data(varInt: outCount)
        let outputsData = outs.reduce(Data()) { $0 + $1.data }
        
        let witnessesData = witnessData.reduce(Data()) { $0 + $1.data }
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }

        return version.data + markerAndFlagData + inputsCountData + inputsData + outputsCountData + outputsData + witnessesData + lockTimeData
    }
    
    var idData: Data {
        let inputsCountData = Data(varInt: inCount)
        let inputsData = ins.reduce(Data()) { $0 + $1.data }
        
        let outputsCountData = Data(varInt: outCount)
        let outputsData = outs.reduce(Data()) { $0 + $1.data }
        
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }

        return version.data + inputsCountData + inputsData + outputsCountData + outputsData + lockTimeData
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
        
        let inputsCount = data.varInt
        data = data.dropFirst(inputsCount.varIntSize)
        
        var inputs = [In]()
        for _ in 0 ..< inputsCount {
            let input = In(data)
            inputs.append(input)
            data = data.dropFirst(input.memSize)
        }

        let outputsCount = data.varInt
        data = data.dropFirst(outputsCount.varIntSize)
        
        var outputs = [Out]()
        for _ in 0 ..< outputsCount {
            let output = Out(data)
            outputs.append(output)
            data = data.dropFirst(output.memSize)
        }

        let witnessesCount = inputsCount
        var witnesses = [Witness]()
        if isSegwit {
            for _ in 0 ..< witnessesCount {
                let witness = Witness(data)
                witnesses.append(witness)
                data = data.dropFirst(witness.memSize)
            }
        }

        let lockTime = data.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)
        
        self.init(version: version, ins: inputs, outs: outputs, witnessData: witnesses, lockTime: lockTime)
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
        doubleHash(idData).reversed().hex
    }

    var wtxid: String {
        doubleHash(data).reversed().hex
    }
}
