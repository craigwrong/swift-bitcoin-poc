import Foundation

func opHash256(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(hash256(first))
    return true
}
