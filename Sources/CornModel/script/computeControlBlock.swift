import Foundation

public func computeControlBlock(internalPubKey: Data, leafInfo: (ScriptTree, Data), merkleRoot: Data) -> Data {
    let (scriptLeaf, path) = leafInfo
    guard case .leaf(let leafVersion, _) = scriptLeaf else {
        fatalError()
    }
    let (_, outputPubKeyYParity) = createTapTweak(pubKey: internalPubKey, merkleRoot: merkleRoot)
    let outputPubKeyYParityBit = UInt8(outputPubKeyYParity ? 1 : 0)
    let controlByte = withUnsafeBytes(of: UInt8(leafVersion) + outputPubKeyYParityBit) { Data($0) }
    return controlByte + internalPubKey + path
}
