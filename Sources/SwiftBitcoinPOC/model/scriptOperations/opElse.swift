import Foundation

func opElse(context: inout ScriptContext) throws {
    
    guard context.pendingElseOperations > 0, context.pendingElseOperations == context.pendingIfOperations.count else {
        throw ScriptError.invalidScript // Else with no corresponding previous if
    }
    context.pendingElseOperations -= 1
    guard let lastEvaluatedIfResult = context.pendingIfOperations.last, let lastEvaluatedIfResult else {
        return
    }
    context.pendingIfOperations[context.pendingIfOperations.endIndex - 1] = !lastEvaluatedIfResult
}
