import Foundation

func opCheckSig(_ stack: inout [Data], context: ExecutionContext) throws {
    let (sig, pubKey) = try getBinaryParams(&stack)

    let result: Bool
    switch context.version {
        case .legacy:
        // Legacy semantics
        result = context.transaction.checkSig(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, script: context.script, opIdx: context.operationIndex)
        case .witnessV0:
        // SegWit V0 semantics
        result = context.transaction.checkSigV0(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, script: context.script, opIdx: context.operationIndex)
        case .witnessV1:
        guard let tapLeafHash = context.tapLeafHash, let keyVersion = context.keyVersion else {
            preconditionFailure()
        }
        
        // https://bitcoin.stackexchange.com/questions/115695/what-are-the-last-bytes-for-in-a-taproot-script-path-sighash
        var codesepPos = UInt32(0xffffffff)
        var i = 0
        while i <= context.operationIndex {
            if context.script.operations[i] == .codeSeparator { codesepPos = UInt32(i) }
            i += 1
        }
        
        // Tapscript semantics
        result = context.transaction.checkSigV1(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOuts: context.previousOutputs, extFlag: 1, tapscriptExt: .init(tapLeafHash: tapLeafHash, keyVersion: keyVersion, codesepPos: codesepPos))
    }
    stack.pushBool(result)
}
