import Foundation
import BigInt

func opCheckSig(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, prevOuts: [Tx.Out], inIdx: Int) -> Bool {
    let result = tx.checkSigLegacy(sig, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], redeemScript: .none)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
