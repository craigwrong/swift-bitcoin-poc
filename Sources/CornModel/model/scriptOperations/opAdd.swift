import Foundation

func opAdd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    var a = ScriptNumber(first)
    let b = ScriptNumber(second)
    try a.add(b)
    stack.append(a.data)
}
