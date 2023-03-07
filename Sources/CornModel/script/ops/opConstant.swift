import Foundation

func opConstant(value k: Int8, stack: inout [Data]) -> Bool {
    let data = withUnsafeBytes(of: k) { Data($0) }
    stack.append(data)
    return true
}
