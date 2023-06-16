import Foundation

func opNegate(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    guard let first = first.asInt32 else {
        throw ScriptError.invalidScript
    }
    stack.pushInt(-first)
}
