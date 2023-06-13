import Foundation

func runScript(_ ops: [Op], stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], version: ScriptVersion = .legacy, tapLeafHash: Data? = .none) throws {
    var context = ExecutionContext(tx: tx, inIdx: inIdx, prevOuts: prevOuts, script: ops, version: version, tapLeafHash: tapLeafHash)
    var i = context.opIdx
    while i < ops.count {
        try ops[i].execute(stack: &stack, context: &context)
        if version == .witnessV1, case .success(_) = ops[i] {
           break
        }
        // Advance iterator if operation itself didn't move it
        if context.opIdx == i { context.opIdx += 1 }
        i = context.opIdx
    }
    if let last = stack.last, last.isZeroIsh {
        throw ScriptError.invalidScript
    }
}
