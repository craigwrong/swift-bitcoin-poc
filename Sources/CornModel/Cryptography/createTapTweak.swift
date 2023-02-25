import Foundation
import ECHelper

public func createTapTweak(pubKey: Data, merkleRoot: Data?) -> (tweakedKey: Data, parity: Bool) {
    let pubKeyPointer = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let merkleRootPointer = merkleRoot?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    var parity: Int32 = -1
    let tweakedKey: [u_char] = .init(unsafeUninitializedCapacity: 32) { tweakedKeyBuffer, tweakedKeyBufferLength in
        let successOrError = createTapTweak(computeTapTweakHashWrapped(_:_:_:), tweakedKeyBuffer.baseAddress, &tweakedKeyBufferLength, &parity, pubKeyPointer, merkleRootPointer)
        precondition(tweakedKeyBufferLength == 32, "Tweaked key must be 32 bytes long.")
        precondition(successOrError == 1, "Could not generate tweak.")
    }
    if parity != 0 && parity != 1 {
        fatalError("Could not calculate parity.")
    }
    return (
        tweakedKey: Data(tweakedKey),
        parity: parity == 1
    )
}
