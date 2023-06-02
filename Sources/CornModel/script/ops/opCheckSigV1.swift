import Foundation

func opCheckSigV1(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptV1, opIdx: Int) -> Bool {
    // TapRoot / TapScript semantics
    let result = tx.checkSigV1(sig, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts)
    // TODO: produce extFlag.. TapRoot vs TapScript
    stack.pushInt(result ? 1 : 0)
    return true
}
