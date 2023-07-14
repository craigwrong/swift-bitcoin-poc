import Foundation

func opSize(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(first)
    let count = first.count
    if count == 0 {
        stack.append(.zero)
    } else {
        stack.pushInt(Int32(count))
    }
}
