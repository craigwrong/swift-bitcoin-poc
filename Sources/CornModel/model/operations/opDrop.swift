import Foundation

func opDrop(_ stack: inout [Data]) throws {
    _ = try getUnaryParam(&stack)
}
