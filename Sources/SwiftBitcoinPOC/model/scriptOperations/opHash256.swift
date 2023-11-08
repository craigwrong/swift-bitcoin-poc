import Foundation

func opHash256(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(hash256(first))
}
