import Foundation

func opRIPEMD160(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    stack.append(RIPEMD160.hash(first))
}
