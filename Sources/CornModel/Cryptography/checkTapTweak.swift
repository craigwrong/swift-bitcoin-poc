import Foundation
import ECHelper

public func checkTapTweak(pubKey: Data, tweakedKey: Data, merkleRoot: Data?, parity: Bool) -> Bool {
    let pubKeyPointer = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let tweakedKeyPointer = tweakedKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let merkleRootPointer = merkleRoot?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (checkTapTweak(computeTapTweakHashWrapped(_:_:_:), pubKeyPointer, tweakedKeyPointer, merkleRootPointer, parity ? 1 : 0) != 0)
}
