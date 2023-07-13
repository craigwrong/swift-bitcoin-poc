import Foundation

func op2Dup(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.append(first)
    stack.append(second)
    stack.append(first)
    stack.append(second)
}
