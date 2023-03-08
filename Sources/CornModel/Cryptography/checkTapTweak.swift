import Foundation
import ECHelper

public func checkTapTweak(pubKey: Data, tweakedKey: Data, merkleRoot: Data?, parity: Bool) -> Bool {
    let pubKeyPtr = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let tweakedKeyPtr = tweakedKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let merkleRootPtr = merkleRoot?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (checkTapTweak(computeTapTweakHashWrapped(_:_:_:), pubKeyPtr, tweakedKeyPtr, merkleRootPtr, parity ? 1 : 0) != 0)
}
