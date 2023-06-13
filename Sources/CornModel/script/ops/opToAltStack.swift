import Foundation

func opToAltStack(_ stack: inout [Data], altStack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    altStack.append(first)
}
