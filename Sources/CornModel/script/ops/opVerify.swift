import Foundation

func opVerify(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    guard !first.isZero else {
        throw ScriptError.invalidScript
    }
}
