import Foundation
import BigInt

func opCheckSig(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: Script, opIdx: Int) -> Bool {
    let result: Bool
    if scriptCode.version == .v0 {
        // SegWit semantics
        result = tx.checkSigV0(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
    } else if scriptCode.version == .v1 {
        // TapRoot / TapScript semantics
        // TODO: produce extFlag.. TapRoot vs TapScript
        result = tx.checkSigV1(sig, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts)
    } else {
        // Legacy semantics
        result = tx.checkSig(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
    }
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
