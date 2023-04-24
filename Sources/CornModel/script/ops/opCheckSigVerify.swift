import Foundation

func opCheckSigVerify(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptLegacy, opIdx: Int) -> Bool {
    if !opCheckSig(sig, pubKey, stack: &stack, tx: tx, inIdx: inIdx, prevOuts: prevOuts, scriptCode: scriptCode, opIdx: opIdx) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
