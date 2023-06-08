import Foundation

extension Array where Element == Data {
    
    /// Memory size as multiple variable length arrays.
    var varLenSize: Int {
        reduce(0) { $0 + $1.varLenSize }
    }

    mutating func popInt() -> Int {
        let d = self.removeLast()
        return d.withUnsafeBytes {
            $0.load(as: Int.self)
        }
    }
    
    mutating func pushInt(_ k: Int) {
        append(Swift.withUnsafeBytes(of: k) { Data($0) })
    }
}
