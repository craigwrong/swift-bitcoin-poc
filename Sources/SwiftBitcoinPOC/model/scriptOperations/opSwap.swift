import Foundation

func opSwap(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.append(second)
    stack.append(first)
}
