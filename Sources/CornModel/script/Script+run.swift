import Foundation
import BigInt

public extension Script {
    func run(stack: inout [Data], transaction: Tx, prevOuts: [Tx.Out], inputIndex: Int) -> Bool {
        let result = ops.reduce(true) { result, op in
            result && op.execute(stack: &stack, transaction: transaction, prevOuts: prevOuts, inputIndex: inputIndex)
        }
        guard result else { return false }
        if let last = stack.last {
            return !BigInt(last).isZero
        }
        return true
    }
}
