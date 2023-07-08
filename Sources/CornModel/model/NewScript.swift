import Foundation

extension Script {
public struct NewScript: ScriptProtocol, Equatable {

    private(set) public var operations: [Operation]
    public let version: Version

    init?(_ data: Data, version: Version = .legacy) {
        self.operations = []
        for i in data.indices {
            guard let operation = Operation(data[i...], version: version) else {
                return nil
            }
            operations.append(operation)
        }
        self.version = version
    }
    
    public init(_ operations: [Operation], version: Version = .legacy) {
        self.operations = operations
        self.version = version
    }
    
    public var data: Data {
        operations.reduce(Data()) { $0 + $1.data }
    }

    public var asm: String {
        operations.reduce("") {
            ($0.isEmpty ? "" : "\($0) ") + $1.asm
        }
    }

    public var dataCount: Int {
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

    public func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data? = .none) throws {
        var context = ScriptContext(transaction: transaction, inputIndex: inIdx, previousOutputs: prevOuts, script: Script(self.data)!, tapLeafHash: tapLeafHash)
        for operation in operations {
            try operation.execute(stack: &stack, context: &context)
            
            // OP_SUCCESS
            if context.succeedUnconditionally { return }
        }
        guard context.pendingIfOperations.isEmpty, context.pendingElseOperations == 0 else {
            throw ScriptError.invalidScript
        }
        if let last = stack.last, last.isZeroIsh {
            throw ScriptError.invalidScript
        }
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

    public static func makeNullData(_ message: String) -> Self {
        guard let messageData = message.data(using: .utf8) else {
            fatalError()
        }
        return .init([
            .return,
            messageData.count == 0 ? .zero : .pushBytes(messageData)
        ])
    }

    public static func makeP2PK(pubKey: Data) -> Self {
        precondition(pubKey.count == 33)
        return .init([
            .pushBytes(pubKey),
            .checkSig
        ])
    }

    public static func makeP2PKH(pubKey: Data) -> Self {
        .init([
            .dup,
            .hash160,
            .pushBytes(hash160(pubKey)),
            .equalVerify,
            .checkSig
        ])
    }

    public static func makeP2MS(sigs: [Data], threshold: Int) -> Self {
        precondition(sigs.count <= UInt8.max && threshold <= sigs.count)
        let threshold = UInt8(1)
        return .init([
            .constant(threshold)
        ] + sigs.map { .pushBytes($0) } + [
            .constant(UInt8(sigs.count)),
            .checkMultiSig
        ])
    }

    public static func makeP2SH(redeemScript: Self) -> Self {
        .init([
            .hash160,
            .pushBytes(hash160(redeemScript.data)),
            .equal
        ])
    }

    public static func makeP2WKH(pubKey: Data) -> Self {
        .init([
            .zero,
            .pushBytes(hash160(pubKey))
        ])
    }

    public static func makeP2WSH(redeemScriptV0: Self) -> Self {
        .init([
            .zero,
            .pushBytes(sha256(redeemScriptV0.data))
        ])
    }

    public static func makeP2TR(outputKey: Data) -> Self {
        precondition(outputKey.count == 32)
        return .init([
            .constant(1),
            .pushBytes(outputKey)
        ])
    }

    static func makeP2WPKH(_ pubKeyHash: Data) -> Self {
        // For P2WPKH witness program, the scriptCode is 0x1976a914{20-byte-pubkey-hash}88ac.
        // OP_DUP OP_HASH160 1d0f172a0ecb48aee1be1f2687d2963ae33f71a1 OP_EQUALVERIFY OP_CHECKSIG
        .init([
            .dup,
            .hash160,
            .pushBytes(pubKeyHash), // prevOut.script.ops[1], // pushBytes 20
            .equalVerify,
            .checkSig
        ], version: .witnessV0)
    }
}
}
