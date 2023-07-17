import Foundation

func opIf(_ stack: inout [Data], isNotIf: Bool = false, context: inout ScriptContext) throws {
    context.pendingElseOperations += 1
    guard context.evaluateBranch else {
        context.pendingIfOperations.append(.none)
        return
    }
    let a = try getUnaryParam(&stack)
    let evalIfBranch = (!isNotIf && ScriptNumber.isTrue(a)) || (isNotIf && ScriptNumber.isFalse(a))
    let evalElseBranch = (!isNotIf && ScriptNumber.isFalse(a)) || (isNotIf && ScriptNumber.isTrue(a))
    guard evalIfBranch || evalElseBranch else {
        throw ScriptError.invalidScript // Minimalif rule violated
    }
    context.pendingIfOperations.append(evalIfBranch)
}
