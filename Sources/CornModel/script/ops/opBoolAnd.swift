import Foundation

func opBoolAnd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    stack.pushBool(!first.isZeroIsh && !second.isZeroIsh)
}
