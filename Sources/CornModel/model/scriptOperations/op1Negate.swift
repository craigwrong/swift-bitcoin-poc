import Foundation

func op1Negate(_ stack: inout [Data]) {
    stack.append(withUnsafeBytes(of: Int8(-1)) { Data($0) })
}
