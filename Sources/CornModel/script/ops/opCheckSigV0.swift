import Foundation
import BigInt

func opCheckSigV0(_ sig: Data, _ pubKey: Data, stack: inout [Data], script: Script, tx: Tx, prevOuts: [Tx.Out], inIdx: Int) -> Bool {
    let result = tx.checkSigV0(sig, pubKey: pubKey, inIdx: inIdx, scriptCode: script, prevOut: prevOuts[inIdx])
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
