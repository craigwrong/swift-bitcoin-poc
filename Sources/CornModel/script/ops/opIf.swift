import Foundation

func opIf(_ stack: inout [Data], isNotIf: Bool = false, context: inout ExecutionContext) throws {
    let first = try getUnaryParam(&stack)
    context.ifCount += 1
    context.pendingElseCount += 1
    if (!isNotIf && first == .one) || (isNotIf && first == .zero) {
        // nothing
    } else if (!isNotIf && first == .zero) || (isNotIf && first == .one) {
        context.evalElse = true
        // Find next else or endif
        var i = context.opIdx
        while i < context.script.count {
            if context.script[i] == .else || context.script[i] == .endIf {
                context.opIdx = i
                return
            }
            i += 1
        }
        throw ScriptError.invalidScript // If without else / endif
    } else {
        throw ScriptError.invalidScript // Minimalif rule broken
    }
}
