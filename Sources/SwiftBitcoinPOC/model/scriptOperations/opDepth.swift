import Foundation

func opDepth(_ stack: inout [Data]) throws {
    let count = try ScriptNumber(stack.count)
    stack.append(count.data)
}
