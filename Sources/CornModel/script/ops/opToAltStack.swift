import Foundation

func opToAltStack(_ stack: inout [Data], context: inout ExecutionContext) throws {
    let first = try getUnaryParam(&stack)
    context.altStack.append(first)
}
