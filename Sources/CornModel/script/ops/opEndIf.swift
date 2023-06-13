import Foundation

func opEndIf(context: inout ExecutionContext) throws {
    guard context.ifCount > 0 else {
        throw ScriptError.invalidScript // To many end-if's
    }
    if context.ifCount == context.pendingElseCount {
        context.pendingElseCount -= 1
    }
    context.ifCount -= 1
    context.evalElse = false
}
