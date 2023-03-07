import Foundation

func opSHA256(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(singleHash(first))
    return true
}
