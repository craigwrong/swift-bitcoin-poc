import Foundation

func opWithin(_ stack: inout [Data]) throws {
    let (first, second, third) = try getTernaryParams(&stack)
    let a = try ScriptNumber(first)
    let min = try ScriptNumber(second)
    let max = try ScriptNumber(third)
    stack.append(ScriptBoolean(min.value <= a.value && a.value < max.value).data)
}
