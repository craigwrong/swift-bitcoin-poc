import Foundation

func opAdd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.pushInt(first.asUInt32 + second.asUInt32)
}
