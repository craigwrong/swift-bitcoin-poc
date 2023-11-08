import Foundation

func opNumEqualVerify(_ stack: inout [Data]) throws {
    try opNumEqual(&stack)
    try opVerify(&stack)
}
