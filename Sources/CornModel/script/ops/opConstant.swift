import Foundation

func opConstant(_ k: Int, stack: inout [Data]) {
    if k == 0 {
        stack.append(Data())
    } else {
        stack.pushInt(k)
    }
}
