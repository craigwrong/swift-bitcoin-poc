import Foundation

func opPushData(data: Data, stack: inout [Data]) -> Bool {
    stack.append(data)
    return true
}
