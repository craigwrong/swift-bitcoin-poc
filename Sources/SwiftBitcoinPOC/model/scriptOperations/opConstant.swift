import Foundation

func opConstant(_ k: UInt8, stack: inout [Data]) {
    stack.append(ScriptNumber(k).data)
}
