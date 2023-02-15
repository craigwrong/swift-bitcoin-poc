import Foundation

public struct Script: Equatable {
    public init(ops: [Script.Op]) {
        self.ops = ops
    }
    
    public let ops: [Op]
}

extension Script {
    var memSize: Int {
        let opsSize = ops.reduce(0) { $0 + $1.memSize }
        return UInt64(opsSize).varIntSize + opsSize
    }
}

public extension Script {

    enum ScriptType: String, Equatable, Decodable {
        case nonStandard = "nonstandard",
             pubKey = "pubkey",
             pubKeyHash = "pubkeyhash",
             scriptHash = "scripthash",
             multiSig = "multisig",
             nullData = "nulldata",
             witnessV0KeyHash = "witness_v0_keyhash",
             witnessV0ScriptHash = "witness_v0_scripthash",
             witnessV1TapRoot = "witness_v1_taproot",
             witnessUnknown = "witness_unknown"
    }
    
    var scriptType: ScriptType {
        if ops.count == 2, ops[1] == .checkSig, case let .pushBytes(data) = ops[0], data.count == 33 {
            return .pubKey
        }
        if ops.count == 5, ops[0] == .dup, ops[1] == .hash160, ops[3] == .equalVerify, ops[4] == .checkSig, case let .pushBytes(data) = ops[2], data.count == 20 {
            return .pubKeyHash
        }
        if ops.count == 3, ops[0] == .hash160, ops[2] == .equal, case let .pushBytes(data) = ops[1], data.count == 20 {
            return .scriptHash
        }
        // TODO: Improve check. Look for "0 ... sigs ... <m> ... addresses ... <n> OP_CHECKMULTISIG".
        if ops.count > 5, ops[0] == .zero, ops.last == .checkMultiSig {
            return .multiSig
        }
        if ops.count == 2, ops[0] == .return, case .pushBytes(_) = ops[1] {
            return .nullData
        }
        if ops.count == 2, ops[0] == .zero, case let .pushBytes(data) = ops[1], data.count == 20 {
            return .witnessV0KeyHash
        }
        if ops.count == 2, ops[0] == .zero, case let .pushBytes(data) = ops[1], data.count == 32 {
            return .witnessV0ScriptHash
        }
        if ops.count == 2, ops[0] == .one, case let .pushBytes(data) = ops[1], data.count == 32 {
            return .witnessV1TapRoot
        }
        if ops.count == 2, ops[0].opCode > Op.one.opCode, ops[0].opCode < Op.sixteen.opCode, case let .pushBytes(data) = ops[1], data.count >= 2, data.count <= 40 {
            return .witnessUnknown
        }
        return .nonStandard
    }
    
    var asm: String {
        ops.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }

    func data(includeLength: Bool = true) -> Data {
        let opsData = ops.reduce(Data()) { $0 + $1.data }
        let lengthData = includeLength ? Data(varInt: UInt64(opsData.count)) : Data()
        return lengthData + opsData
    }
    
    init(_ data: Data, includeLength: Bool = true) {
        var data = data
        if includeLength {
            let length = data.varInt
            data = data.dropFirst(length.varIntSize)
            data = data[..<(data.startIndex + Int(length))]
        }
        var newOps = [Op]()
        while data.count > 0 {
            let op = Op.fromData(data)
            newOps.append(op)
            data = data.dropFirst(op.memSize)
        }
        ops = newOps
    }
}
