import Foundation

func op1Add(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    var a = try ScriptNumber(first)
    try a.add(.one)
    stack.append(a.data)
}
