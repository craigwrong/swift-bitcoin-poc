import Foundation

extension Array where Element == String {
    var varLengthSize: Int {
        reduce(0) { $0 + $1.varLengthSize }
    }
}
