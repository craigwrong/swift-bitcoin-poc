import Foundation

func op1Sub(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    var a = ScriptNumber(first)
    try a.add(.negativeOne)
    stack.append(a.data)
}
