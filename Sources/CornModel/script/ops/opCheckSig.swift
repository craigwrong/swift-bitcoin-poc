import Foundation

func opCheckSig(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptLegacy, opIdx: Int) -> Bool {
    // Legacy semantics
    let result = tx.checkSig(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
    stack.pushInt(result ? 1 : 0)
    return true
}
