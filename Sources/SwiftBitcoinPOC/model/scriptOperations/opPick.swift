import Foundation

func opPick(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    let i = try ScriptNumber(first).value
    guard stack.count > i else {
        throw ScriptError.invalidScript
    }
    let picked = stack[stack.endIndex - i]
    stack.append(picked)
}
