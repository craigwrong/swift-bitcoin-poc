import Foundation

func opHash160(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(hash160(first))
    return true
}
