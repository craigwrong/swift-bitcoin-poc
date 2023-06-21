import Foundation

public extension Transaction.Input {
    struct Witness: Equatable {
        private(set) var elements: [Data]
    }
}
