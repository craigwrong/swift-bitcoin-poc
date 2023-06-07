import Foundation

func opCheckMultiSigVerify(_ n: Int, _ m: Int, _ pubKeys: [Data], _ sigs: [Data], stack: inout [Data], context: ExecutionContext) -> Bool {
    if !opCheckMultiSig(n, m, pubKeys, sigs, stack: &stack, context: context) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
