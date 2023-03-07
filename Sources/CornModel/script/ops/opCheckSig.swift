import Foundation
import BigInt

func opCheckSig(_ signature: Data, _ pubKey: Data, stack: inout [Data], transaction: Tx, prevOuts: [Tx.Out], inputIndex: Int) -> Bool {
    let result = transaction.checkSigLegacy(signature, pubKey: pubKey, inputIndex: inputIndex, previousTxOut: prevOuts[inputIndex], redeemScript: .none)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
