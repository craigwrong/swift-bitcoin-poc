import Foundation

func opSub(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    var a = try ScriptNumber(first)
    var b = try ScriptNumber(second)
    b.negate()
    try a.add(b)
    stack.append(a.data)
}
