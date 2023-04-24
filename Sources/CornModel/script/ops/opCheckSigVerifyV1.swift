import Foundation

func opCheckSigVerifyV1(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptV1, opIdx: Int) -> Bool {
    if !opCheckSigV1(sig, pubKey, stack: &stack, tx: tx, inIdx: inIdx, prevOuts: prevOuts, scriptCode: scriptCode, opIdx: opIdx) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
