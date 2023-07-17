import Foundation

func opBoolAnd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.append(ScriptNumber(ScriptNumber(first) != .zero && ScriptNumber(second) != .zero).data)
}
