import Foundation

func opCheckMultiSigVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    try opCheckMultiSig(&stack, context: context)
    try opVerify(&stack)
}
