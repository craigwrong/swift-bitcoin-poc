import Foundation

func getUnaryParam(_ stack: inout [Data]) throws -> Data {
    guard stack.count > 0 else {
        throw ScriptError.invalidScript
    }
    return stack.removeLast()
}

func getBinaryParams(_ stack: inout [Data]) throws -> (Data, Data) {
    guard stack.count > 1 else {
        throw ScriptError.invalidScript
    }
    let second = stack.removeLast()
    let first = stack.removeLast()
    return (first, second)
}

func getTernaryParams(_ stack: inout [Data]) throws -> (Data, Data, Data) {
    guard stack.count > 2 else {
        throw ScriptError.invalidScript
    }
    let third = stack.removeLast()
    let (first, second) = try getBinaryParams(&stack)
    return (first, second, third)
}

func getCheckMultiSigParams(_ stack: inout [Data]) throws -> (Int, [Data], Int, [Data]) {
    guard stack.count > 4 else {
        throw ScriptError.invalidScript
    }
    let n = Int(stack.popInt8())
    let pubKeys = Array(stack[(stack.endIndex - n)...].reversed())
    stack.removeLast(n)
    let m = Int(stack.popInt8())
    let sigs = Array(stack[(stack.endIndex - m)...].reversed())
    stack.removeLast(m)
    let nullDummy = stack.removeLast()
    guard nullDummy.count == 0 else {
        throw ScriptError.invalidScript
    }
    return (n, pubKeys, m, sigs)
}
