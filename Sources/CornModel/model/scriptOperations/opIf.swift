import Foundation

func opIf(_ stack: inout [Data], isNotIf: Bool = false, context: inout ScriptContext) throws {
    context.pendingElseOperations += 1
    guard context.evaluateBranch else {
        context.pendingIfOperations.append(.none)
        return
    }
    let first = try getUnaryParam(&stack)
    let condition = try ScriptBoolean(minimalData: first)
    let evalIfBranch = (!isNotIf && condition.value) || (isNotIf && !condition.value)
    context.pendingIfOperations.append(evalIfBranch)
}
