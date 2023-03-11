import Foundation

public struct Script: Equatable {
    
    public init(_ ops: [Script.Op], version: Version = .legacy) {
        self.ops = ops
        self.version = version
    }
    
    public var ops: [Op]
    public var version: Version
}

public extension Script {

    init(_ data: Data, version: Version = .legacy, includesLength: Bool = true) {
        var data = data
        if includesLength {
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
        self.version = version
    }

    var witnessProgram: Data {
        precondition(scriptType == .witnessV0KeyHash || scriptType == .witnessV0ScriptHash || scriptType == .witnessV1TapRoot || scriptType == .witnessUnknown)
        guard case let .pushBytes(programData) = ops[1] else {
            fatalError()
        }
        return programData
    }

    var scriptType: LockScriptType {
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
            return .multiSig(-1, -1)
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
        if ops.count == 2, ops[0] == .constant(1), case let .pushBytes(data) = ops[1], data.count == 32 {
            return .witnessV1TapRoot
        }
        if ops.count == 2, ops[0].opCode > Op.constant(1).opCode, ops[0].opCode < Op.constant(16).opCode, case let .pushBytes(data) = ops[1], data.count >= 2, data.count <= 40 {
            return .witnessUnknown
        }
        return .nonStandard
    }
    
    var asm: String {
        ops.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }
}

extension Script {
    
    var memSize: Int {
        let opsSize = ops.reduce(0) { $0 + $1.memSize }
        return UInt64(opsSize).varIntSize + opsSize
    }

    func data(includeLength: Bool = true) -> Data {
        let opsData = ops.reduce(Data()) { $0 + $1.data }
        let lengthData = includeLength ? Data(varInt: UInt64(opsData.count)) : Data()
        return lengthData + opsData
    }
    
    mutating func removeSubScripts(before opIdx: Int) {
        if let previousCodeSeparatorIdx = ops.indices.last(where : { i in
            ops[i] == .codeSeparator && i < opIdx
        }) {
            ops = .init(ops.dropFirst(previousCodeSeparatorIdx + 1))
        }
    }
    
    mutating func removeCodeSeparators() {
        ops.removeAll { $0 == .codeSeparator }
    }
}
