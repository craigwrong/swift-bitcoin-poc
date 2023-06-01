import Foundation
import ECCHelper

public func getOutputKey(privKey: Data) -> Data {
    let (outputKey, _) = createTapTweak(pubKey: getInternalKey(privKey: privKey), merkleRoot: .none)
    return outputKey
}
