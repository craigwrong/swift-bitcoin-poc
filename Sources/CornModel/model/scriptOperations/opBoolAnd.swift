import Foundation

func opBoolAnd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    let a = try ScriptNumber(first)
    let b = try ScriptNumber(second)
    // stack.append(ScriptBoolean(first).and(ScriptBoolean(second)).data)
    stack.append(ScriptBoolean(a != .zero && b != .zero).data)
}
