import Foundation
import BigInt

func opEqual(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    let result = BigInt(first) == BigInt(second)
    stack.append(result ? Data.one : Data.zero)
    return true
}
