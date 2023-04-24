import Foundation
import BigInt

func opCheckSigV0(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptV0, opIdx: Int) -> Bool {
    // SegWit V0 semantics
    let result = tx.checkSigV0(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
