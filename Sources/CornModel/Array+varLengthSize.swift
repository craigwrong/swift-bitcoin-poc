import Foundation

extension Array where Element == Data {
    var varLengthSize: Int {
        reduce(0) { $0 + $1.varLengthSize }
    }
}
