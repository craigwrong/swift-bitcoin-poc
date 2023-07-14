import Foundation

func opAdd(_ stack: inout [Data]) throws {
    let (first, second) = try getBinaryParams(&stack)
    guard let first = first.asInt32, let second = second.asInt32 else {
        throw ScriptError.invalidScript
    }
    stack.pushInt(first &+ second)
}
