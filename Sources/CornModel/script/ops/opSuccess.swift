import Foundation

func opSuccess(stack: inout [Data]) -> Bool {
    // if scriptCode.version == .v1 {
    stack.removeAll() // TODO: Maybe there is a more elegant way to make the script succeed
    return true
}
