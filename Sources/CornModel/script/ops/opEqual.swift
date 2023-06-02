import Foundation

func opEqual(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    let result = first == second
    stack.pushInt(result ? 1 : 0)
    return true
}
