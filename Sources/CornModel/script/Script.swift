import Foundation

protocol Script: Equatable {
    func runScript(stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out]) -> Bool
}
