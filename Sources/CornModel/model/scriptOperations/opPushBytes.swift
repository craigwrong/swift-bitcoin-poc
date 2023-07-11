import Foundation

func opPushData(data: Data, stack: inout [Data]) {
    stack.append(data)
}
