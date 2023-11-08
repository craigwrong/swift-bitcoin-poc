import Foundation

func opBoolOr(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    let a = try ScriptNumber(first)
    let b = try ScriptNumber(second)
    stack.append(ScriptBoolean(a != .zero || b != .zero).data)
}
