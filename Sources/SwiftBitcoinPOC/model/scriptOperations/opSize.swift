import Foundation

func opSize(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(first)
    let n = try ScriptNumber(first.count)
    stack.append(n.data)
}
