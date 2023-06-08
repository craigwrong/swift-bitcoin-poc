import Foundation

func runScript(_ ops: [Op], stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], version: ScriptVersion = .legacy, tapLeafHash: Data? = .none) throws {
    var context = ExecutionContext(tx: tx, inIdx: inIdx, prevOuts: prevOuts, script: ops, version: version, tapLeafHash: tapLeafHash)
    var i = context.opIdx
    while i < ops.count {
        try ops[i].execute(stack: &stack, context: context)
        if version == .witnessV1, case .success(_) = ops[i] {
           break
        }
        i += 1
        context.opIdx = i
    }
    if let last = stack.last, last.isZero {
        throw ScriptError.invalidScript
    }
}
