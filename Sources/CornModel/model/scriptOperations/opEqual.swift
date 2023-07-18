import Foundation

func opEqual(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.append(ScriptBoolean(first == second).data)
}
