import Foundation
import BigInt

func opCheckSig(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: ScriptLegacy, opIdx: Int) -> Bool {
    // Legacy semantics
    let result = tx.checkSig(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
