import Foundation

func opToAltStack(_ stack: inout [Data], context: inout ScriptContext) throws {
    let first = try getUnaryParam(&stack)
    context.altStack.append(first)
}
