import Foundation

extension Array where Element == Data {

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

extension Data {
    var isZero: Bool {
        return reduce(true) {
            $0 && $1 == 0
        }
    }
}
