import Foundation

func opRoll(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    let i = try ScriptNumber(first).value
    guard stack.count > i else {
        throw ScriptError.invalidScript
    }
    let rolled = stack.remove(at: stack.endIndex - i)
    stack.append(rolled)
}
