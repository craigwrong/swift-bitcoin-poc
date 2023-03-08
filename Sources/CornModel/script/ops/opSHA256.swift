import Foundation

func opSHA256(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(sha256(first))
    return true
}
