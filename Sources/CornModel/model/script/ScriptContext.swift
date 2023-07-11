import Foundation

struct ScriptContext {
    let transaction: Transaction
    let inputIndex: Int
    let previousOutputs: [Transaction.Output]
    let script: any Script
    var decodedOperations = [ScriptOperation]()
    var operationIndex: Int = 0
    var programCounter: Int = 0
    var lastCodeSeparatorIndex: Int? = .none // For tapscript
    var lastCodeSeparatorOffset: Int? = .none // For segwit and legacy
    private(set) var succeedUnconditionally = false
    let tapLeafHash: Data?
    let keyVersion: UInt8? = 0
    var altStack: [Data] = []
    
    var pendingIfOperations = [Bool?]()
    var pendingElseOperations = 0

    var previousOutput: Transaction.Output {
        previousOutputs[inputIndex]
    }

    var evaluateBranch: Bool {
        guard let lastEvaluatedIfResult = pendingIfOperations.last(where: { $0 != .none }), let lastEvaluatedIfResult else {
            return true
        }
        return lastEvaluatedIfResult
    }

    func getScriptCode(signature: Data) -> Data? {
        var scriptData = script.data
        if let codesepOffset = lastCodeSeparatorOffset {
            scriptData.removeFirst(codesepOffset + 1)
        }
        
        var scriptCode = Data()
        var programCounter2 = scriptData.startIndex
        while programCounter2 < scriptData.count {
            guard let operation = ScriptOperation(scriptData[programCounter2...], version: script.version) else {
                return .none
            }
            if operation != .codeSeparator && operation != .pushBytes(signature) {
                scriptCode.append(operation.data)
            }
            programCounter2 += operation.dataCount
        }

        // TODO: FindAndDelete signatures
        /*
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let subScript: Script
        if prevOut.script.outputType == .scriptHash {
            // TODO: This check might be redundant as the given script code should always be the redeem script in p2sh checksig
            if let op = Script(inputs[inIdx].script.data)!.operations.last, case let .pushBytes(redeemScriptRaw) = op, Script(redeemScriptRaw)! != scriptCode {
                preconditionFailure()
            }
            subScript = scriptCode
        } else {
            // TODO: Account for code separators. Find the last executed one and remove anything before it. After that, remove all remaining OP_CODESEPARATOR instances from script code
            var scriptCode = scriptCode
            scriptCode.removeSubScripts(before: opIdx)
            scriptCode.removeCodeSeparators()
            subScript = scriptCode
            // TODO: FindAndDelete any signature data in subScript (coming scriptPubKey, not standard to have sigs there anyway).
        }
        */
        
        return scriptCode
    }

    var scriptCodeV0: Data {
        var scriptData = script.data
        // if the witnessScript contains any OP_CODESEPARATOR, the scriptCode is the witnessScript but removing everything up to and including the last executed OP_CODESEPARATOR before the signature checking opcode being executed, serialized as scripts inside CTxOut.
        if let codesepOffset = lastCodeSeparatorOffset {
            scriptData.removeFirst(codesepOffset + 1)
        }
        return scriptData
    }
    
    var codeSeparatorPosition: UInt32 {
        // https://bitcoin.stackexchange.com/questions/115695/what-are-the-last-bytes-for-in-a-taproot-script-path-sighash
        if let index = lastCodeSeparatorIndex { UInt32(index) } else { UInt32(0xffffffff) }
    }
    
    mutating func setSucceedUnconditionally() {
        if !succeedUnconditionally {
            succeedUnconditionally.toggle()
        }
    }
}
