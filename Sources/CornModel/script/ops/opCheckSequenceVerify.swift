import Foundation

func opCheckSequenceVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    let first = try getUnaryParam(&stack)
    guard !first.isZeroIsh else {
        throw ScriptError.invalidScript
    }
}
