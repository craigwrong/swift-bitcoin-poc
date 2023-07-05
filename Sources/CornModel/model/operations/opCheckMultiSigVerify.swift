import Foundation

func opCheckMultiSigVerify(_ stack: inout [Data], context: ScriptContext) throws {
    try opCheckMultiSig(&stack, context: context)
    try opVerify(&stack)
}
