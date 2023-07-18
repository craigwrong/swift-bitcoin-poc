import Foundation

func opNot(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    let a = try ScriptNumber(first)
    stack.append(ScriptBoolean(a == .zero).data)
}
