import Foundation

public struct ScriptV1: Equatable {
    
    public init(_ ops: [ScriptV1.Op]) {
        self.ops = ops
    }
    
    public var ops: [Op]
}

public extension ScriptV1 {

    init(_ data: Data) {
        var data = data
        var newOps = [Op]()
        while data.count > 0 {
            let op = Op.fromData(data)
            newOps.append(op)
            data = data.dropFirst(op.memSize)
        }
        ops = newOps
    }

    var asm: String {
        ops.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }
    
    var data: Data {
        ops.reduce(Data()) { $0 + $1.data }
    }
}

extension ScriptV1 {
    
    var memSize: Int {
        let opsSize = ops.reduce(0) { $0 + $1.memSize }
        return UInt64(opsSize).varIntSize + opsSize
    }
    
    static func keyHashScript(_ outputKey: Data) -> Self {
        .init([.pushBytes(outputKey), .checkSig])
    }
}
