import Foundation
import BigInt

func opCheckSigV1(_ sig: Data, _ pubKey: Data, stack: inout [Data], script: Script, tx: Tx, prevOuts: [Tx.Out], inIdx: Int, extFlag: UInt8) -> Bool {
    let result = tx.checkSigV1(sig, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts, extFlag: extFlag)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
