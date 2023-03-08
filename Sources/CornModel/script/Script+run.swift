import Foundation
import BigInt

public extension Script {
    func run(stack: inout [Data], tx: Tx, prevOuts: [Tx.Out], inIdx: Int) -> Bool {
        let result = ops.reduce(true) { result, op in
            result && op.execute(stack: &stack, tx: tx, prevOuts: prevOuts, inIdx: inIdx)
        }
        guard result else { return false }
        if let last = stack.last {
            return !BigInt(last).isZero
        }
        return true
    }
}
