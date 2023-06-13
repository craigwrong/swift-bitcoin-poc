import Foundation

func opConstant(_ k: UInt8, stack: inout [Data]) {
    if k == 0 {
        stack.append(.zero)
    } else {
        stack.pushInt(k)
    }
}
