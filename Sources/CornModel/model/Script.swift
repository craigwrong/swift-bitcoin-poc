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

    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data?) throws
    
    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output]) throws
}

extension Script {

    public func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output]) throws {
        try run(&stack, transaction: transaction, inIdx: inIdx, prevOuts: prevOuts, tapLeafHash: .none)
    }

    public var prefixedData: Data {
        data.varLenData
    }
    
    public var prefixedDataCount: Int {
        data.varLenSize
    }
}
