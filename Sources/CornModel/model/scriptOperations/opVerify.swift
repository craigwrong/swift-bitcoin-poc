import Foundation

func opVerify(_ stack: inout [Data]) throws {
    let first = try getUnaryParam(&stack)
    guard ScriptBoolean(first).value else {
        throw ScriptError.invalidScript
    }
}
