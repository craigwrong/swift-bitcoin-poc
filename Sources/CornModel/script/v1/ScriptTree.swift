import Foundation

public indirect enum ScriptTree: Equatable {
    // leaf_version is 0xc0 (or 0xc1) for BIP342
    case leaf(Int, [ScriptV1.Op]), branch(Self, Self)

    /// Calculates the merkle root as well as some additional tree info for generating control blocks.
    func calcMerkleRoot() -> ([(ScriptTree, Data)], Data) {
        switch self {
        case .leaf(_, _):
            return ([(self, Data())], leafHash)
        case .branch(let scriptTreeLeft, let scriptTreeRight):
            let (left, leftHash) = scriptTreeLeft.calcMerkleRoot()
            let (right, rightHash) = scriptTreeRight.calcMerkleRoot()
            let ret = left.map { ($0, $1 + rightHash) } + right.map { ($0, $1 + leftHash) }
            let invertHashes = rightHash.hex < leftHash.hex
            let newLeftHash = invertHashes ? rightHash : leftHash
            let newRightHash = invertHashes ? leftHash : rightHash
            let branchHash = taggedHash(tag: "TapBranch", payload: newLeftHash + newRightHash)
            return (ret, branchHash)
        }
    }

    func leafs() -> [(Int, ScriptTree)] {
        var count = 0
        return leafs(partialResult: [], counter: &count)
    }
    
    private func leafs(partialResult: [(Int, ScriptTree)], counter: inout Int) -> [(Int, ScriptTree)] {
        switch self {
        case .leaf(_, _):
            let ret = partialResult + [(counter, self)]
            counter += 1
            return ret
        case .branch(let scriptTreeLeft, let scriptTreeRight):
            return scriptTreeLeft.leafs(partialResult: partialResult, counter: &counter) + scriptTreeRight.leafs(partialResult: partialResult, counter: &counter)
        }
    }
    
    var leafHash: Data {
        guard case .leaf(let version, let script) = self else {
            preconditionFailure("Needs to be a leaf.")
        }
        let leafVersionData = withUnsafeBytes(of: UInt8(version)) { Data($0) }
        return taggedHash(tag: "TapLeaf", payload: leafVersionData + script.data.varLenData)
    }
    
    public func getOutputKey(privKey: Data) -> Data {
        let (_, merkleRoot) = calcMerkleRoot()
        return CornModel.getOutputKey(privKey: privKey, merkleRoot: merkleRoot)
    }
    
}
