import Foundation

func opRIPEMD160(_ first: Data, stack: inout [Data]) -> Bool {
    stack.append(RIPEMD160.hash(first))
    return true
}
