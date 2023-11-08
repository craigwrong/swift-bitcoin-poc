import Foundation

func opHash160(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(hash160(first))
}
