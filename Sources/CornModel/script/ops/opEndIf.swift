import Foundation

func opEndIf(context: inout ExecutionContext) throws {
    guard context.pendingIfs > 0 else {
        throw ScriptError.invalidScript // To many end-if's
    }
    if context.pendingIfs == context.pendingElses {
        context.pendingElses -= 1
    }
    context.pendingIfs -= 1
    context.evalElse = false
}
