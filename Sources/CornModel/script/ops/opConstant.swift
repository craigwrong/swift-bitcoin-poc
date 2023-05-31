import Foundation
import BigInt

func opConstant(value k: Int8, stack: inout [Data]) -> Bool {
    //let data = withUnsafeBytes(of: Int16(k).byteSwapped) { Data($0) }
    let data = BigInt(clamping: k).serialize()
    stack.append(data)
    return true
}
