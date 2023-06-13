import Foundation

func opIfDup(_ stack: inout [Data]) throws {
    guard let top = stack.last else {
        throw ScriptError.invalidScript
    }
    if top.isEmpty {
        return
    }
    try opDup(&stack)
}
