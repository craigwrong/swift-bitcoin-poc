import Foundation

func opEndIf(context: inout ScriptContext) throws {
    guard !context.pendingIfOperations.isEmpty else {
        throw ScriptError.invalidScript // End if with no corresponding previous if
    }
    if context.pendingElseOperations == context.pendingIfOperations.count {
        context.pendingElseOperations -= 1 // try opElse(context: &context)
    } else if context.pendingElseOperations != context.pendingIfOperations.count - 1 {
        throw ScriptError.invalidScript // Unbalanced else
    }
    context.pendingIfOperations.removeLast()
}
