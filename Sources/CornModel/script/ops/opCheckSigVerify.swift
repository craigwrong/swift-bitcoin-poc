import Foundation

func opCheckSigVerify(_ sig: Data, _ pubKey: Data, stack: inout [Data], context: ExecutionContext) -> Bool {
    if !opCheckSig(sig, pubKey, stack: &stack, context: context) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
