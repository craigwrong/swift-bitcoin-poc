import Foundation

extension ScriptV0: Script {
    func run(stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        var result = true
        var i = 0
        while result && i < ops.count {
            result = ops[i].execute(stack: &stack, tx: tx, inIdx: inIdx, prevOuts: prevOuts, scriptCode: self, opIdx: i)
            i += 1
        }
        guard result else { return false }
        if let last = stack.last {
            return !last.isZero
        }
        return true
    }
}
