import Foundation

func opEqual(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    let result = first == second
    stack.pushInt(result ? 1 : 0)
}
