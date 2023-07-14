import Foundation

func opRoll(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    guard let i32 = first.asInt32 else {
        throw ScriptError.invalidScript
    }
    let i = Int(i32)
    guard stack.count > i else {
        throw ScriptError.invalidScript
    }
    let rolled = stack.remove(at: stack.endIndex - i)
    stack.append(rolled)
}
