import Foundation

public struct ScriptV1: Equatable {
    
    public init(_ ops: [ScriptV1.Op], leafVersion: UInt8 = 0xc0) {
        self.ops = ops
        tapLeafHash = taggedHash(tag: "TapLeaf", payload: Data([leafVersion]) + ops.data.varLenData)
    }
    
    var ops: [Op]
    var tapLeafHash: Data
    var keyVersion = UInt8(0)

    init(_ data: Data, tapLeafHash: Data) {
        ops = [Op].fromData(data)
        self.tapLeafHash = tapLeafHash
    }

    var asm: String {
        ops.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }
    
    var data: Data { ops.data }
    
    var dataLen: Int {
        let opsSize = ops.reduce(0) { $0 + $1.dataLen }
        return UInt64(opsSize).varIntSize + opsSize
    }
}
