import Foundation

func opEqual(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.append(ScriptNumber(first == second).data)
}
