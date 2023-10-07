import Foundation

public protocol Script: Equatable {

    var version: ScriptVersion { get }
    var data: Data { get }
    var size: Int { get }
    var prefixedData: Data { get }
    var prefixedSize: Int { get }
    
    var asm: String { get }

    static var empty: Self { get }
    var isEmpty: Bool { get }
    var parsed: ParsedScript? { get }
    var serialized: SerializedScript { get }

    func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Output], tapLeafHash: Data?) throws
    
    func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Output]) throws
}

extension Script {

    public func run(_ stack: inout [Data], transaction: Transaction, inputIndex: Int, previousOutputs: [Output]) throws {
        try run(&stack, transaction: transaction, inputIndex: inputIndex, previousOutputs: previousOutputs, tapLeafHash: .none)
    }

    public var prefixedData: Data {
        data.varLenData
    }
    
    public var prefixedSize: Int {
        data.varLenSize
    }
}
