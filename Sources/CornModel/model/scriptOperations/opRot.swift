import Foundation

func opRot(_ stack: inout [Data]) throws {
    let (first, second, third) = try getTernaryParams(&stack)
    stack.append(second)
    stack.append(third)
    stack.append(first)
}
