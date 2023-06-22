import Foundation

func opSHA256(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(sha256(first))
}
