import Foundation

func opFromAltStack(_ stack: inout [Data], context: inout ExecutionContext) throws {
    guard context.altStack.count > 0 else {
        throw ScriptError.invalidScript
    }
    stack.append(context.altStack.removeLast())
}
