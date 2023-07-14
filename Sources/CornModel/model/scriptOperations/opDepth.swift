import Foundation

func opDepth(_ stack: inout [Data]) {
    let count = stack.count
    if count == 0 {
        stack.append(.zero)
    } else {
        stack.pushInt(Int32(count))
    }
}
