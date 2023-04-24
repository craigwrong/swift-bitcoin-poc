import Foundation

public protocol Script: Equatable {
    func run(stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out]) -> Bool
}
