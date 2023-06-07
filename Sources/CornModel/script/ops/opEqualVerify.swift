import Foundation

func opEqualVerify(_ stack: inout [Data]) throws {
    try opEqual(&stack)
    try opVerify(&stack)
}
