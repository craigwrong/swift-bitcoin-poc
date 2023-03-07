import Foundation

func opEqualVerify(_ first: Data, _ second: Data, stack: inout [Data]) -> Bool {
    if !opEqual(first, second, stack: &stack) {
        return false
    }
    guard let first = try? getUnaryParam(&stack) else {
        return false
    }
    return opVerify(first, stack: &stack)
}
