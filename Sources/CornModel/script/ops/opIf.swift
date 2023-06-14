import Foundation

func opIf(_ stack: inout [Data], isNotIf: Bool = false, context: inout ExecutionContext) throws {
    let first = try getUnaryParam(&stack)
    context.pendingIfs += 1
    context.pendingElses += 1
    if (!isNotIf && first == .zero) || (isNotIf && first == .one) {
        // Else case
        context.evalElse = true
        
        // Find next else or endif
        var pendingIfs = -1
        var pendingElses = -1
        var i = context.opIdx
        while i < context.script.count {
            if context.script[i] == .if || context.script[i] == .notIf {
                pendingIfs += 1
                pendingElses += 1
            }
            if context.script[i] == .else {
                if pendingElses > 0 {
                    pendingElses -= 1
                } else {
                    context.opIdx = i
                    return
                }
            }
            if context.script[i] == .endIf {
                if pendingIfs > 0 {
                    pendingIfs -= 1
                    if pendingElses > pendingIfs {
                        pendingElses -= 1
                    }
                } else {
                    context.opIdx = i
                    return
                }
            }
            i += 1
        }
        throw ScriptError.invalidScript // If without else / endif
    } else if (isNotIf || first != .one) && (!isNotIf || first != .zero) {
        // Not else case, neither the if case
        throw ScriptError.invalidScript // Minimalif rule broken
    }
}
