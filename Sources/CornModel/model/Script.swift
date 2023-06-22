import Foundation

public enum ScriptError: Error {
    case invalidScript
}

public struct Script: Equatable {

    public enum Version: String {
        case legacy, witnessV0, witnessV1
    }

    private(set) public var operations: [Operation]
    public let version: Version
    
    public init(_ operations: [Operation], version: Script.Version = .legacy) {
        self.operations = operations
        self.version = version
    }
    
    init(_ data: Data, version: Version = .legacy) {
        operations = [Operation]()
        self.version = version
        var data = data
        while data.count > 0 {
            let op = Operation(data, version: version)
            operations.append(op)
            data = data.dropFirst(op.dataLen)
        }
    }
    
    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data? = .none) throws {
        var context = ExecutionContext(transaction: transaction, inputIndex: inIdx, previousOutputs: prevOuts, script: self, version: version, tapLeafHash: tapLeafHash)
        var i = context.operationIndex
        while i < operations.count {
            try operations[i].execute(stack: &stack, context: &context)
            if version == .witnessV1, case .success(_) = operations[i] {
               break
            }
            // Advance iterator if operation itself didn't move it
            if context.operationIndex == i { context.operationIndex += 1 }
            i = context.operationIndex
        }
        if let last = stack.last, last.isZeroIsh {
            throw ScriptError.invalidScript
        }
    }


    var witnessProgram: Data {
        precondition(lockType == .witnessV0KeyHash || lockType == .witnessV0ScriptHash || lockType == .witnessV1TapRoot || lockType == .witnessUnknown)
        guard case let .pushBytes(programData) = operations[1] else {
            fatalError()
        }
        return programData
    }

    var lockType: LockType {
        if operations.count == 2, operations[1] == .checkSig, case let .pushBytes(data) = operations[0], data.count == 33 {
            return .pubKey
        }
        if operations.count == 5, operations[0] == .dup, operations[1] == .hash160, operations[3] == .equalVerify, operations[4] == .checkSig, case let .pushBytes(data) = operations[2], data.count == 20 {
            return .pubKeyHash
        }
        if operations.count == 3, operations[0] == .hash160, operations[2] == .equal, case let .pushBytes(data) = operations[1], data.count == 20 {
            return .scriptHash
        }
        if operations.count > 3, operations.last == .checkMultiSig {
            return .multiSig
        }
        if operations.count == 2, operations[0] == .return, case .pushBytes(_) = operations[1] {
            return .nullData
        }
        if operations.count == 2, operations[0] == .zero, case let .pushBytes(data) = operations[1], data.count == 20 {
            return .witnessV0KeyHash
        }
        if operations.count == 2, operations[0] == .zero, case let .pushBytes(data) = operations[1], data.count == 32 {
            return .witnessV0ScriptHash
        }
        if operations.count == 2, operations[0] == .constant(1), case let .pushBytes(data) = operations[1], data.count == 32 {
            return .witnessV1TapRoot
        }
        if operations.count == 2, operations[0].opCode > Operation.constant(1).opCode, operations[0].opCode < Operation.constant(16).opCode, case let .pushBytes(data) = operations[1], data.count >= 2, data.count <= 40 {
            return .witnessUnknown
        }
        return .nonStandard
    }
    
    var asm: String {
        operations.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }
    
    var data: Data {
        operations.reduce(Data()) { $0 + $1.data }
    }
    
    var dataLen: Int {
        let opsSize = operations.reduce(0) { $0 + $1.dataLen }
        return UInt64(opsSize).varIntSize + opsSize
    }

    mutating func removeSubScripts(before opIdx: Int) {
        if let previousCodeSeparatorIdx = operations.indices.last(where : { i in
            operations[i] == .codeSeparator && i < opIdx
        }) {
            operations = .init(operations.dropFirst(previousCodeSeparatorIdx + 1))
        }
    }
    
    mutating func removeCodeSeparators() {
        operations.removeAll { $0 == .codeSeparator }
    }

    public static func makeNullData(_ message: String) -> Script {
        guard let messageData = message.data(using: .utf8) else {
            fatalError()
        }
        return Script([
            .return,
            messageData.count == 0 ? .zero : .pushBytes(messageData)
        ])
    }

    public static func makeP2PK(pubKey: Data) -> Script {
        precondition(pubKey.count == 33)
        return Script([
            .pushBytes(pubKey),
            .checkSig
        ])
    }

    public static func makeP2PKH(pubKey: Data) -> Script {
        Script([
            .dup,
            .hash160,
            .pushBytes(hash160(pubKey)),
            .equalVerify,
            .checkSig
        ])
    }

    public static func makeP2MS(sigs: [Data], threshold: Int) -> Script {
        precondition(sigs.count <= UInt8.max && threshold <= sigs.count)
        let threshold = UInt8(1)
        return Script([
            .constant(threshold)
        ] + sigs.map { .pushBytes($0) } + [
            .constant(UInt8(sigs.count)),
            .checkMultiSig
        ])
    }

    public static func makeP2SH(redeemScript: Script) -> Script {
        Script([
            .hash160,
            .pushBytes(hash160(redeemScript.data)),
            .equal
        ])
    }

    public static func makeP2WKH(pubKey: Data) -> Script {
        Script([
            .zero,
            .pushBytes(hash160(pubKey))
        ])
    }

    public static func makeP2WSH(redeemScriptV0: Script) -> Script {
        Script([
            .zero,
            .pushBytes(sha256(redeemScriptV0.data))
        ])
    }

    public static func makeP2TR(outputKey: Data) -> Script {
        precondition(outputKey.count == 32)
        return .init([
            .constant(1),
            .pushBytes(outputKey)
        ])
    }

    static func makeP2WPKH(_ pubKeyHash: Data) -> Script {
        // For P2WPKH witness program, the scriptCode is 0x1976a914{20-byte-pubkey-hash}88ac.
        // OP_DUP OP_HASH160 1d0f172a0ecb48aee1be1f2687d2963ae33f71a1 OP_EQUALVERIFY OP_CHECKSIG
        Script([
            .dup,
            .hash160,
            .pushBytes(pubKeyHash), // prevOut.script.ops[1], // pushBytes 20
            .equalVerify,
            .checkSig
        ], version: .witnessV0)
    }
}
