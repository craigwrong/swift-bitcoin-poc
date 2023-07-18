import Foundation

func opSHA1(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(sha1(first))
}
