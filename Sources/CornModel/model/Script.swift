import Foundation

public enum ScriptError: Error {
    case nonStandardScript,
         unknownWitnessVersion,
         invalidScript,
         invalidInstruction
}

public struct Script: Equatable {

    public enum Version: String {
        case legacy, witnessV0, witnessV1
    }

    public static let empty = Self([])
    
    private(set) public var operations: [Operation]
    public let version: Version
    
    public init(_ operations: [Operation], version: Script.Version = .legacy) {
        self.operations = operations
        self.version = version
    }
    
    init?(_ data: Data, version: Version = .legacy) {
        operations = [Operation]()
        self.version = version
        var data = data
        while data.count > 0 {
            guard let op = Operation(data, version: version) else {
                return nil
            }
            operations.append(op)
            data = data.dropFirst(op.dataCount)
        }
    }


    
    func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data? = .none) throws {
        var context = ScriptContext(transaction: transaction, inputIndex: inIdx, previousOutputs: prevOuts, script: self, tapLeafHash: tapLeafHash)
        var i = context.operationIndex
        while i < operations.count {
            try operations[i].execute(stack: &stack, context: &context)
            
            // OP_SUCCESS
            if context.succeedUnconditionally { return }

            // Advance iterator if operation itself didn't move it
            if context.operationIndex == i { context.operationIndex += 1 }
            i = context.operationIndex
        }
        guard context.pendingIfOperations.isEmpty, context.pendingElseOperations == 0 else {
            throw ScriptError.invalidScript
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

    /// Finds out the standard script type without fully decoding.
    static func lockType(forScriptData data: Data) -> LockType {
    
        let opCodeSize = 1
        let count = data.count
                
        // P2PK
        
        let compressedPKSize = 33
        let p2pkCompressedSize = opCodeSize + compressedPKSize + opCodeSize // 35
        if count == p2pkCompressedSize, case let .pushBytes(payload) = Operation(data), payload.count == compressedPKSize, let lastOp = Operation(data.dropFirst(opCodeSize + compressedPKSize)), lastOp == .checkSig {
            return .pubKey
        }

        let uncompressedPKSize = 65
        let p2pkUncompressedSize = opCodeSize + uncompressedPKSize + opCodeSize // 67
        if count == p2pkUncompressedSize, case let .pushBytes(payload) = Operation(data), payload.count == uncompressedPKSize, let lastOp = Operation(data.dropFirst(opCodeSize + uncompressedPKSize)), lastOp == .checkSig {
            return .pubKey
        }

        let pkHashSize = 20
        let p2pkhSize = opCodeSize + opCodeSize + opCodeSize + pkHashSize + opCodeSize + opCodeSize // 25
        if count == p2pkhSize,
            let op0 = Operation(data), op0 == .dup,
            let op1 = Operation(data.dropFirst(opCodeSize)), op1 == .hash160,
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize + opCodeSize)), payload.count == pkHashSize,
            let op3 = Operation(data.dropFirst(opCodeSize + opCodeSize + opCodeSize + pkHashSize)), op3 == .equalVerify,
            let op4 = Operation(data.dropFirst(opCodeSize + opCodeSize + opCodeSize + pkHashSize + opCodeSize)), op4 == .checkSig {
            return .pubKeyHash
        }

        let p2shSize = opCodeSize + opCodeSize + pkHashSize + opCodeSize // 23
        if count == p2shSize,
            let op0 = Operation(data), op0 == .hash160,
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == pkHashSize,
            let op2 = Operation(data.dropFirst(opCodeSize + opCodeSize + pkHashSize)), op2 == .equal {
            return .scriptHash
        }
        
        // Multisig
        let p2msMinSize = opCodeSize + 1 * (opCodeSize + compressedPKSize) + opCodeSize + opCodeSize
        // Max script is 15 of 15 compressed key multisig: 15 * (33 + 1) + 1 + 1 + 1 = 513
        let p2msMaxSize = opCodeSize + 15 * (opCodeSize + compressedPKSize) + opCodeSize + opCodeSize
        if count >= p2msMinSize, count <= p2msMaxSize,
           let opLast = Operation(data.dropFirst(data.count - 1)), opLast == .checkMultiSig,
           case let .constant(n) = Operation(data.dropFirst(data.count - 2)), n <= 15,
           case let .constant(m) = Operation(data), m <= n
         {
            // TODO: Decode all push operations (pubkeys), check their individual lengths and check total count.
            return .multiSig
        }

        // Null data (OP_RETURN)
        
        // Just OP_RETURN
        if count == opCodeSize,
            let op0 = Operation(data), op0 == .return {
            return .nullData
        }

        // OP_RETURN 0
        if count == opCodeSize + opCodeSize,
            let op0 = Operation(data), op0 == .return,
            let op1 = Operation(data.dropFirst()), op1 == .zero {
            return .nullData
        }

        // OP_RETURN OP_CONSTANT_1..16
        if count == opCodeSize + opCodeSize,
            let op0 = Operation(data), op0 == .return,
            case .constant(_) = Operation(data.dropFirst(opCodeSize)) {
            return .nullData
        }

        // OP_RETURN OP_PUSH_BYTES 1...75
        let nullDataLimit = 80
        let maxPushBytes = 75
        let minNullDataScriptPushBytes = opCodeSize + opCodeSize + 1
        let maxNullDataScriptPushBytes = opCodeSize + opCodeSize + maxPushBytes
        let pushBytesCount = data.count - (opCodeSize + opCodeSize)
        if count >= minNullDataScriptPushBytes, count <= maxNullDataScriptPushBytes,
            let op0 = Operation(data), op0 == .return,
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == pushBytesCount {
            return .nullData
        }

        // OP_RETURN OP_PUSH_DATA1 LENGTH 76...80
        let pushData1Size = opCodeSize + 1
        let minNullDataScriptPushData1 = opCodeSize + pushData1Size + (maxPushBytes + 1)
        let maxNullDataScriptPushData1 = opCodeSize + pushData1Size + nullDataLimit
        let pushData1Count = data.count - (opCodeSize + pushData1Size)
        if count >= minNullDataScriptPushData1, count <= maxNullDataScriptPushData1,
            let op0 = Operation(data), op0 == .return,
            case let .pushData1(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == pushData1Count {
            return .nullData
        }
        
        // TODO: Support PUSH_DATA1, PUSH_DATA2 and PUSH_DATA4 for 0 to 80 bytes for nullData scripts even if it's a suboptimal use.

        // p2wkh
        let p2wkhSize = opCodeSize + opCodeSize + pkHashSize // 22
        if count == p2wkhSize,
            let op0 = Operation(data), op0 == .zero,
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == pkHashSize {
            return .witnessV0KeyHash
        }
        
        // p2wsh
        let witnessScriptHashSize = 32
        let p2wshSize = opCodeSize + opCodeSize + witnessScriptHashSize // 34
        if count == p2wshSize,
            let op0 = Operation(data), op0 == .zero,
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == witnessScriptHashSize {
            return .witnessV0ScriptHash
        }
        
        // p2tr
        if count == p2wshSize,
            let op0 = Operation(data), op0 == .constant(1),
            case let .pushBytes(payload) = Operation(data.dropFirst(opCodeSize)), payload.count == witnessScriptHashSize {
            return .witnessV1TapRoot
        }
        
        // In this case non-standard will include undecodable/potentially undecodable scripts.
        return .nonStandard
    }
    
    var lockType: LockType {
        // Compressed pk are 33 bytes, uncompressed 65
        if operations.count == 2, operations[1] == .checkSig, case let .pushBytes(data) = operations[0], (data.count == 33 || data.count == 65) {
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
        if (operations.count == 1 && operations[0] == .return) ||
           (operations.count == 2 && operations[0] == .return && operations[1] == .zero)
        {
            return .nullData
        }
        if operations.count == 2, operations[0] == .return, case .constant(_) = operations[1] {
            return .nullData
        }
        if operations.count == 2, operations[0] == .return, case .pushBytes(_) = operations[1] {
            return .nullData
        }
        if operations.count == 2, operations[0] == .return, case let .pushData1(data) = operations[1], data.count > 75, data.count <= 80 {
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
    
    var dataCount: Int {
        let opsSize = operations.reduce(0) { $0 + $1.dataCount }
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
