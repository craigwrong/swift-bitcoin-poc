import Foundation
import BigInt

func opBoolAnd(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    let result = !BigInt(first).isZero && !BigInt(second).isZero
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
