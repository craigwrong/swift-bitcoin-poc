@testable import CornModel
import Foundation

extension ParsedScript {
    func run(_ stack: inout [Data]) throws {
        try run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])
    }
}

extension Array where Element == Data {
    static func withConstants(_ constants: [Int]) -> Self {
        constants.compactMap {
            (try? ScriptNumber($0))?.data ?? .none
        }
    }

    static func withConstants(_ constants: Int...) -> Self {
        withConstants(constants)
    }
}
