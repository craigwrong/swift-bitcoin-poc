import Foundation

public protocol ScriptProtocol: Equatable {

    var data: Data { get }
    var dataCount: Int { get }
    
    var asm: String { get }

    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data?) throws
    
    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output]) throws
}

extension ScriptProtocol {

    public func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output]) throws {
        try run(&stack, transaction: transaction, inIdx: inIdx, prevOuts: prevOuts, tapLeafHash: .none)
    }
}
