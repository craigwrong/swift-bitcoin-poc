import Foundation
import BigInt

extension ScriptV1: Script {
    public func run(stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        var result = true
        var i = 0
        while result && i < ops.count {
            result = ops[i].execute(stack: &stack, tx: tx, inIdx: inIdx, prevOuts: prevOuts, scriptCode: self, opIdx: i)
            if case .success(_) = ops[i] {
               break
            }
            i += 1
        }
        guard result else { return false }
        if let last = stack.last {
            return !BigInt(last).isZero
        }
        return true
    }
}
