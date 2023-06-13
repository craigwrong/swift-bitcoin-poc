import Foundation

func opElse(context: inout ExecutionContext) throws {
    guard context.ifCount > 0 && context.ifCount == context.pendingElseCount else {
        throw ScriptError.invalidScript // To many else's before end-if
    }
    context.pendingElseCount -= 1
    if !context.evalElse {
        // Find next endif
        var i = context.opIdx
        while i < context.script.count {
            if context.script[i] == .endIf {
                context.opIdx = i
                return
            }
            i += 1
        }
        throw ScriptError.invalidScript // Else without matching endif
    }
}
