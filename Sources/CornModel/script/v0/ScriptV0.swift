import Foundation

public struct ScriptV0: Equatable {
    
    public init(_ ops: [ScriptV0.Op]) {
        self.ops = ops
    }
    
    var ops: [Op]
}

extension ScriptV0 {

    init(_ data: Data) {
        var data = data
        var newOps = [Op]()
        while data.count > 0 {
            let op = Op.fromData(data)
            newOps.append(op)
            data = data.dropFirst(op.dataLen)
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

extension ScriptV0 {
    
    var dataLen: Int {
        let opsSize = ops.reduce(0) { $0 + $1.dataLen }
        return UInt64(opsSize).varIntSize + opsSize
    }

    mutating func removeSubScripts(before opIdx: Int) {
        if let previousCodeSeparatorIdx = ops.indices.last(where : { i in
            ops[i] == .codeSeparator && i < opIdx
        }) {
            ops = .init(ops.dropFirst(previousCodeSeparatorIdx + 1))
        }
    }

    static func keyHashScript(_ pubKeyHash: Data) -> Self {
        // For P2WPKH witness program, the scriptCode is 0x1976a914{20-byte-pubkey-hash}88ac.
        // OP_DUP OP_HASH160 1d0f172a0ecb48aee1be1f2687d2963ae33f71a1 OP_EQUALVERIFY OP_CHECKSIG
        .init([
            .dup,
            .hash160,
            .pushBytes(pubKeyHash), // prevOut.scriptPubKey.ops[1], // pushBytes 20
            .equalVerify,
            .checkSig
        ])
    }
}
