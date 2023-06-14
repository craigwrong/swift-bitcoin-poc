import Foundation

func opElse(context: inout ExecutionContext) throws {
    guard context.pendingIfs > 0 && context.pendingIfs == context.pendingElses else {
        throw ScriptError.invalidScript // To many else's before end-if
    }
    context.pendingElses -= 1
    if !context.evalElse {
        // Find next endif
        var pendingIfs = 0
        var i = context.opIdx
        while i < context.script.count {
            if context.script[i] == .if || context.script[i] == .notIf {
                pendingIfs += 1
            }
            if context.script[i] == .endIf {
                if pendingIfs > 0 {
                    pendingIfs -= 1
                } else {
                    context.opIdx = i
                    return
                }
            }
            i += 1
        }
        throw ScriptError.invalidScript // Else without matching endif
    }
}
