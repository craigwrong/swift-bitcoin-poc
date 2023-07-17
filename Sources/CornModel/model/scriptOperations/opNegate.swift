import Foundation

func opNegate(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    var a = ScriptNumber(first)
    a.negate()
    stack.append(a.data)
}
