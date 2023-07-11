import Foundation

func opOneNegate(_ stack: inout [Data]) {
    stack.append(withUnsafeBytes(of: Int8(-1)) { Data($0) })
}
