import Foundation

func opVerify(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    guard ScriptNumber(first) != .zero else {
        throw ScriptError.invalidScript
    }
}
