import Foundation

func opConstant(_ k: Int32, stack: inout [Data]) {
    if k == 0 {
        stack.append(Data())
    } else {
        stack.pushInt(k)
    }
}
