import Foundation

public func getOutputKey(privKey: Data, merkleRoot: Data? = .none) -> Data {
    getOutputKey(internalKey: getInternalKey(privKey: privKey), merkleRoot: merkleRoot)
}

func getOutputKey(internalKey: Data, merkleRoot: Data? = .none) -> Data {
    let (outputKey, _) = createTapTweak(pubKey: internalKey, merkleRoot: merkleRoot)
    return outputKey
}
