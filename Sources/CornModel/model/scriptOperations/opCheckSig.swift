import Foundation

func opCheckSig(_ stack: inout [Data], context: ScriptContext) throws {
    let (sig, publicKey) = try getBinaryParams(&stack)

    let result: Bool
    switch context.script.version {
        case .legacy:
        // Legacy semantics
        guard let scriptCode = context.getScriptCode(signature: sig) else {
            throw ScriptError.invalidScript
        }
        result = context.transaction.checkSignature(extendedSignature: sig, publicKey: publicKey, inputIndex: context.inputIndex, previousOutput: context.previousOutput, scriptCode: scriptCode)
        case .witnessV0:
            // SegWit V0 semantics
            result = context.transaction.checkSegwitSignature(extendedSignature: sig, publicKey: publicKey, inputIndex: context.inputIndex, previousOutputs: context.previousOutput, scriptCode: context.scriptCodeV0)
        case .witnessV1:
        guard let tapLeafHash = context.tapLeafHash, let keyVersion = context.keyVersion else {
            preconditionFailure()
        }
        
        // Tapscript semantics
        result = context.transaction.checkTaprootSignature(extendedSignature: sig, publicKey: publicKey, inputIndex: context.inputIndex, previousOutputs: context.previousOutputs, extFlag: 1, tapscriptExtension: .init(tapLeafHash: tapLeafHash, keyVersion: keyVersion, codesepPos: context.codeSeparatorPosition))
    }
    stack.append(ScriptBoolean(result).data)
}
