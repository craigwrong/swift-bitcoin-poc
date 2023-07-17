import Foundation

func op1Negate(_ stack: inout [Data]) {
    stack.append(ScriptNumber.negativeOne.data)
}
