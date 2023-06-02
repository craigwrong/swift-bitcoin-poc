import Foundation

func opBoolAnd(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    let result = !first.isZero && !second.isZero
    stack.pushInt(result ? 1 : 0)
    return true
}
