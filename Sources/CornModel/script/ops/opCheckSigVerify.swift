import Foundation

func opCheckSigVerify(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, prevOuts: [Tx.Out], inIdx: Int) -> Bool {
    if !opCheckSig(sig, pubKey, stack: &stack, tx: tx, prevOuts: prevOuts, inIdx: inIdx) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
