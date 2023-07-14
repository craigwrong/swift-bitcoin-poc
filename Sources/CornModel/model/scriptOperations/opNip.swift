import Foundation

func opNip(_ stack: inout [Data]) throws {
    let (_, second) = try getBinaryParams(&stack)
    stack.append(second)
}
