import Foundation

extension Array where Element == Op {

    init(_ data: Data) {
        var data = data
        var newOps = [Op]()
        while data.count > 0 {
            let op = Op(data)
            newOps.append(op)
            data = data.dropFirst(op.dataLen)
        }
        self = newOps
    }

    var witnessProgram: Data {
        precondition(scriptType == .witnessV0KeyHash || scriptType == .witnessV0ScriptHash || scriptType == .witnessV1TapRoot || scriptType == .witnessUnknown)
        guard case let .pushBytes(programData) = self[1] else {
            fatalError()
        }
        return programData
    }

    var scriptType: LockScriptType {
        if count == 2, self[1] == .checkSig, case let .pushBytes(data) = self[0], data.count == 33 {
            return .pubKey
        }
        if count == 5, self[0] == .dup, self[1] == .hash160, self[3] == .equalVerify, self[4] == .checkSig, case let .pushBytes(data) = self[2], data.count == 20 {
            return .pubKeyHash
        }
        if count == 3, self[0] == .hash160, self[2] == .equal, case let .pushBytes(data) = self[1], data.count == 20 {
            return .scriptHash
        }
        if count > 3, last == .checkMultiSig {
            return .multiSig
        }
        if count == 2, self[0] == .return, case .pushBytes(_) = self[1] {
            return .nullData
        }
        if count == 2, self[0] == .zero, case let .pushBytes(data) = self[1], data.count == 20 {
            return .witnessV0KeyHash
        }
        if count == 2, self[0] == .zero, case let .pushBytes(data) = self[1], data.count == 32 {
            return .witnessV0ScriptHash
        }
        if count == 2, self[0] == .constant(1), case let .pushBytes(data) = self[1], data.count == 32 {
            return .witnessV1TapRoot
        }
        if count == 2, self[0].opCode > Op.constant(1).opCode, self[0].opCode < Op.constant(16).opCode, case let .pushBytes(data) = self[1], data.count >= 2, data.count <= 40 {
            return .witnessUnknown
        }
        return .nonStandard
    }
    
    var asm: String {
        reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }
    
    var data: Data {
        reduce(Data()) { $0 + $1.data }
    }
    
    var dataLen: Int {
        let opsSize = reduce(0) { $0 + $1.dataLen }
        return UInt64(opsSize).varIntSize + opsSize
    }

    mutating func removeSubScripts(before opIdx: Int) {
        if let previousCodeSeparatorIdx = indices.last(where : { i in
            self[i] == .codeSeparator && i < opIdx
        }) {
            self = .init(dropFirst(previousCodeSeparatorIdx + 1))
        }
    }
    
    mutating func removeCodeSeparators() {
        removeAll { $0 == .codeSeparator }
    }
}
