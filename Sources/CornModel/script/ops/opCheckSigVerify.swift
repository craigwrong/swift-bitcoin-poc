import Foundation

func opCheckSigVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    try opCheckSig(&stack, context: context)
    try opVerify(&stack)
}
