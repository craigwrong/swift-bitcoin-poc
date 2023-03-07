import Foundation

func opCheckSigVerify(_ signature: Data, _ pubKey: Data, stack: inout [Data], transaction: Tx, prevOuts: [Tx.Out], inputIndex: Int) -> Bool {
    if !opCheckSig(signature, pubKey, stack: &stack, transaction: transaction, prevOuts: prevOuts, inputIndex: inputIndex) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
