import Foundation
import BigInt

func opVerify(_ first: Data, stack: inout [Data]) -> Bool {
    BigInt(first).isZero
}
