import Foundation

func opCheckMultiSigVerifyV0(_ n: Int, _ m: Int, _ pubKeys: [Data], _ sigs: [Data], stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptV0, opIdx: Int) -> Bool {
    if !opCheckMultiSigV0(n, m, pubKeys, sigs, stack: &stack, tx: tx, inIdx: inIdx, prevOuts: prevOuts, scriptCode: scriptCode, opIdx: opIdx) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
