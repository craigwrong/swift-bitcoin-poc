import Foundation

public struct SerializedScript: Script {

    public static let empty = Self(.init())
    private(set) public var data: Data
    public let version: ScriptVersion

    init(_ data: Data, version: ScriptVersion = .legacy) {
        self.data = data
        self.version = version
    }
    
    init(prefixedData: Data, version: ScriptVersion = .legacy) {
        self.init(Data(varLenData: prefixedData), version: version)
    }
    
    public var dataCount: Int {
       data.count
    }
    
    public var asm: String {
        "" // TODO: convert to decoded script and call its asm method
    }

    public var isEmpty: Bool {
        data.isEmpty
    }
    
    public var decoded: ParsedScript? {
        ParsedScript(data, version: version)
    }

    public var serialized: SerializedScript { self }

    public func run(_ stack: inout [Data], transaction: Transaction, inIdx: Int, prevOuts: [Transaction.Output], tapLeafHash: Data? = .none) throws {
        var context = ScriptContext(transaction: transaction, inputIndex: inIdx, previousOutputs: prevOuts, script: self, tapLeafHash: tapLeafHash)
        
        while context.programCounter < data.count {
            let startIndex = data.startIndex + context.programCounter
            guard let operation = ScriptOperation(data[startIndex...], version: version) else {
                throw ScriptError.invalidInstruction
            }
            
            if operation == .codeSeparator {
                context.lastCodeSeparatorIndex = context.decodedOperations.count
                context.lastCodeSeparatorOffset = context.programCounter
            }
            context.decodedOperations.append(operation)
            context.programCounter += operation.dataCount
                        
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
    
    /// Finds out the standard script type without fully decoding.
    var outputType: OutputType {
    
        let opCodeSize = 1
        let count = data.count
                
        // P2PK
        
        let compressedPKSize = 33
        let p2pkCompressedSize = opCodeSize + compressedPKSize + opCodeSize // 35
        if count == p2pkCompressedSize, case let .pushBytes(payload) = ScriptOperation(data), payload.count == compressedPKSize, let lastOp = ScriptOperation(data.dropFirst(opCodeSize + compressedPKSize)), lastOp == .checkSig {
            return .pubKey
        }

        let uncompressedPKSize = 65
        let p2pkUncompressedSize = opCodeSize + uncompressedPKSize + opCodeSize // 67
        if count == p2pkUncompressedSize, case let .pushBytes(payload) = ScriptOperation(data), payload.count == uncompressedPKSize, let lastOp = ScriptOperation(data.dropFirst(opCodeSize + uncompressedPKSize)), lastOp == .checkSig {
            return .pubKey
        }

        let pkHashSize = 20
        let p2pkhSize = opCodeSize + opCodeSize + opCodeSize + pkHashSize + opCodeSize + opCodeSize // 25
        if count == p2pkhSize,
            let op0 = ScriptOperation(data), op0 == .dup,
            let op1 = ScriptOperation(data.dropFirst(opCodeSize)), op1 == .hash160,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize + opCodeSize)), payload.count == pkHashSize,
            let op3 = ScriptOperation(data.dropFirst(opCodeSize + opCodeSize + opCodeSize + pkHashSize)), op3 == .equalVerify,
            let op4 = ScriptOperation(data.dropFirst(opCodeSize + opCodeSize + opCodeSize + pkHashSize + opCodeSize)), op4 == .checkSig {
            return .pubKeyHash
        }

        let p2shSize = opCodeSize + opCodeSize + pkHashSize + opCodeSize // 23
        if count == p2shSize,
            let op0 = ScriptOperation(data), op0 == .hash160,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == pkHashSize,
            let op2 = ScriptOperation(data.dropFirst(opCodeSize + opCodeSize + pkHashSize)), op2 == .equal {
            return .scriptHash
        }
        
        // Multisig
        let p2msMinSize = opCodeSize + 1 * (opCodeSize + compressedPKSize) + opCodeSize + opCodeSize
        // Max script is 15 of 15 compressed key multisig: 15 * (33 + 1) + 1 + 1 + 1 = 513
        let p2msMaxSize = opCodeSize + 15 * (opCodeSize + compressedPKSize) + opCodeSize + opCodeSize
        if count >= p2msMinSize, count <= p2msMaxSize,
           let opLast = ScriptOperation(data.dropFirst(data.count - 1)), opLast == .checkMultiSig,
           case let .constant(n) = ScriptOperation(data.dropFirst(data.count - 2)), n <= 15,
           case let .constant(m) = ScriptOperation(data), m <= n
         {
            // TODO: Decode all push operations (pubkeys), check their individual lengths and check total count.
            return .multiSig
        }

        // Null data (OP_RETURN)
        
        // Just OP_RETURN
        if count == opCodeSize,
            let op0 = ScriptOperation(data), op0 == .return {
            return .nullData
        }

        // OP_RETURN 0
        if count == opCodeSize + opCodeSize,
            let op0 = ScriptOperation(data), op0 == .return,
            let op1 = ScriptOperation(data.dropFirst()), op1 == .zero {
            return .nullData
        }

        // OP_RETURN OP_CONSTANT_1..16
        if count == opCodeSize + opCodeSize,
            let op0 = ScriptOperation(data), op0 == .return,
            case .constant(_) = ScriptOperation(data.dropFirst(opCodeSize)) {
            return .nullData
        }
        
        // OP_RETURN OP_PUSH_BYTES 1...75
        let nullDataLimit = 80
        let maxPushBytes = 75
        let minNullDataScriptPushBytes = opCodeSize + opCodeSize + 1
        let maxNullDataScriptPushBytes = opCodeSize + opCodeSize + maxPushBytes
        let pushBytesCount = data.count - (opCodeSize + opCodeSize)
        if count >= minNullDataScriptPushBytes, count <= maxNullDataScriptPushBytes,
            let op0 = ScriptOperation(data), op0 == .return,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == pushBytesCount {
            return .nullData
        }

        // OP_RETURN OP_PUSH_DATA1 LENGTH 76...80
        let pushData1Size = opCodeSize + 1
        let minNullDataScriptPushData1 = opCodeSize + pushData1Size + (maxPushBytes + 1)
        let maxNullDataScriptPushData1 = opCodeSize + pushData1Size + nullDataLimit
        let pushData1Count = data.count - (opCodeSize + pushData1Size)
        if count >= minNullDataScriptPushData1, count <= maxNullDataScriptPushData1,
            let op0 = ScriptOperation(data), op0 == .return,
            case let .pushData1(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == pushData1Count {
            return .nullData
        }
        
        // TODO: support multiple constant/byte pushes (?)
        // TODO: Support PUSH_DATA1, PUSH_DATA2 and PUSH_DATA4 for 0 to 80 bytes for nullData scripts even if it's a suboptimal use.

        // p2wkh
        let p2wkhSize = opCodeSize + opCodeSize + pkHashSize // 22
        if count == p2wkhSize,
            let op0 = ScriptOperation(data), op0 == .zero,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == pkHashSize {
            return .witnessV0KeyHash
        }
        
        // p2wsh
        let witnessScriptHashSize = 32
        let p2wshSize = opCodeSize + opCodeSize + witnessScriptHashSize // 34
        if count == p2wshSize,
            let op0 = ScriptOperation(data), op0 == .zero,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == witnessScriptHashSize {
            return .witnessV0ScriptHash
        }
        
        // p2tr
        if count == p2wshSize,
            let op0 = ScriptOperation(data), op0 == .constant(1),
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count == witnessScriptHashSize {
            return .witnessV1TapRoot
        }
        
        // Witnes unknown version
        if count == p2wshSize,
            let op0 = ScriptOperation(data), op0 == .constant(1),
            case let .constant(k) = ScriptOperation(data), k > 1, k <= 16,
            case let .pushBytes(payload) = ScriptOperation(data.dropFirst(opCodeSize)), payload.count >= 2, payload.count <= 40 {
            return .witnessUnknown
        }
        
        // In this case non-standard will include undecodable/potentially undecodable scripts.
        return .nonStandard
    }

    var witnessProgram: Data {
        precondition(outputType == .witnessV0KeyHash || outputType == .witnessV0ScriptHash || outputType == .witnessV1TapRoot || outputType == .witnessUnknown)
        guard case let .pushBytes(programData) = ScriptOperation(data.dropFirst()) else {
            fatalError() // Should never reach here
        }
        return programData
    }
}
