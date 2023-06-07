import Foundation

func opBoolAnd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    let result = !first.isZero && !second.isZero
    stack.pushInt(result ? 1 : 0)
}
