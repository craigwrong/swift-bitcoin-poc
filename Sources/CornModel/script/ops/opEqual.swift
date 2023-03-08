import Foundation
import BigInt

func opEqual(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    let result = BigInt(first) == BigInt(second)
    stack.append(result ? BigInt(1).serialize() : BigInt.zero.serialize())
    return true
}
