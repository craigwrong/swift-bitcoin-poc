import Foundation

func opDup(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(first)
    stack.append(first)
    return true
}
