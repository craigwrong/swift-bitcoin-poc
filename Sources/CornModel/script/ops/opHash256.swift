import Foundation

func opHash256(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(doubleHash(first))
    return true
}
