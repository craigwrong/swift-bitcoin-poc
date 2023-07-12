import Foundation

public protocol Script: Equatable {

    var version: ScriptVersion { get }
    var data: Data { get }
    var dataCount: Int { get }
    var prefixedData: Data { get }
    var prefixedDataCount: Int { get }
    
    var asm: String { get }

    static var empty: Self { get }
    var isEmpty: Bool { get }
    var parsed: ParsedScript? { get }
    var serialized: SerializedScript { get }

    func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Transaction.Output], merkleRoot: Data?, tapLeafHash: Data?) throws
    
    func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Transaction.Output]) throws
}

extension Script {

    public func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Transaction.Output]) throws {
        try run(&stack, transaction: transaction, inputIndex: inputIndex, previousOutputs: previousOutputs, merkleRoot: .none, tapLeafHash: .none)
    }

    public var prefixedData: Data {
        data.varLenData
    }
    
    public var prefixedDataCount: Int {
        data.varLenSize
    }
}
