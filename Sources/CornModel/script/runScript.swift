import Foundation

func runScript(_ ops: [Op], stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], version: ScriptVersion = .legacy, leafVersion: UInt8? = .none) -> Bool {
    var context = ExecutionContext(tx: tx, inIdx: inIdx, prevOuts: prevOuts, script: ops, version: version, leafVersion: leafVersion)
    var result = true
    var i = context.opIdx
    while result && i < ops.count {
        result = ops[i].execute(stack: &stack, context: context)
        if version == .witnessV1, case .success(_) = ops[i] {
           break
        }
        i += 1
        context.opIdx = i
    }
    guard result else { return false }
    if let last = stack.last {
        return !last.isZero
    }
    return true
}
