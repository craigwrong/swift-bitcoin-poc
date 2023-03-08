import Foundation

extension Array where Element == Data {
    
    /// Memory size as multiple variable length arrays.
    var varLenSize: Int {
        reduce(0) { $0 + $1.varLenSize }
    }
}
