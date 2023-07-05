import Foundation

func opIf(_ stack: inout [Data], isNotIf: Bool = false, context: inout ScriptContext) throws {
    context.pendingElseOperations += 1
    guard context.evaluateBranch else {
        context.pendingIfOperations.append(.none)
        return
    }
    let first = try getUnaryParam(&stack)
    let evalIfBranch = (!isNotIf && first == .one) || (isNotIf && first == .zero)
    let evalElseBranch = (!isNotIf && first == .zero) || (isNotIf && first == .one)
    guard evalIfBranch || evalElseBranch else {
        throw ScriptError.invalidScript // Minimalif rule violated
    }
    context.pendingIfOperations.append(evalIfBranch)
}
