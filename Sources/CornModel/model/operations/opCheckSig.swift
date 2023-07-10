import Foundation

func opCheckSig(_ stack: inout [Data], context: ScriptContext) throws {
    let (sig, pubKey) = try getBinaryParams(&stack)

    let result: Bool
    switch context.script.version {
        case .legacy:
        // Legacy semantics
        guard let scriptCode = context.scriptCode else {
            throw ScriptError.invalidScript
        }
        result = context.transaction.checkSig(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, scriptCode: scriptCode)
        case .witnessV0:
            // SegWit V0 semantics
            result = context.transaction.checkSigV0(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, scriptCode: context.scriptCodeV0)
        case .witnessV1:
        guard let tapLeafHash = context.tapLeafHash, let keyVersion = context.keyVersion else {
            preconditionFailure()
        }
        
        // Tapscript semantics
        result = context.transaction.checkSigV1(sig, pubKey: pubKey, inIdx: context.inputIndex, prevOuts: context.previousOutputs, extFlag: 1, tapscriptExt: .init(tapLeafHash: tapLeafHash, keyVersion: keyVersion, codesepPos: context.codeSeparatorPosition))
    }
    stack.pushBool(result)
}
