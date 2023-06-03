import Foundation

func computeMerkleRoot(controlBlock: Data, tapLeafHash: Data) -> Data {
    let pathLen = (controlBlock.count - 33) / 32
    var k = tapLeafHash
    for i in 0 ..< pathLen {
        let startIdx = controlBlock.startIndex.advanced(by: 33 + 32 * i)
        let endIdx = startIdx + 32
        let node = controlBlock[startIdx ... endIdx]
        let payload = k.hex > node.hex ? k + node : node + k
        k = taggedHash(tag: "TapBranch", payload: payload)
    }
    return k
}
