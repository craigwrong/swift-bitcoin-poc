import Foundation

func opCheckMultiSig(_ stack: inout [Data], context: ScriptContext) throws {
    let (n, pubKeys, m, sigs) = try getCheckMultiSigParams(&stack)
    precondition(m <= n)
    precondition(pubKeys.count == n)
    precondition(sigs.count == m)
    var leftPubKeys = pubKeys
    var leftSigs = sigs
    while leftPubKeys.count > 0 && leftSigs.count > 0 {
        let pubKey = leftPubKeys.removeFirst()
        var result = false
        var i = 0
        while i < leftSigs.count {
            switch context.script.version {
                case .legacy:
                guard let scriptCode = context.getScriptCode(signature: leftSigs[i]) else {
                    throw ScriptError.invalidScript
                }
                result = context.transaction.checkSignature(extendedSignature: leftSigs[i], publicKey: pubKey, inputIndex: context.inputIndex, previousOutput: context.previousOutput, scriptCode: scriptCode)
                case .witnessV0:
                result = context.transaction.checkSegwitSignature(extendedSignature: leftSigs[i], publicKey: pubKey, inputIndex: context.inputIndex, previousOutputs: context.previousOutput, scriptCode: context.scriptCodeV0)
                case .witnessV1:
                fatalError()
            }
            if result {
                break
            }
            i += 1
        }
        if result {
            leftSigs.remove(at: i)
        }
    }
    stack.pushBool(leftSigs.count == 0)
}
