import Foundation

func opCheckMultiSig(_ stack: inout [Data], context: ScriptContext) throws {
    let (n, pubKeys, m, sigs) = try getCheckMultiSigParams(&stack)
    precondition(m <= n)
    precondition(pubKeys.count == n)
    precondition(sigs.count == m)
    precondition(context.script.version == .legacy || context.script.version == .witnessV0)
    var leftPubKeys = pubKeys
    var leftSigs = sigs
    while leftPubKeys.count > 0 && leftSigs.count > 0 {
        let pubKey = leftPubKeys.removeFirst()
        var result = false
        var i = 0
        while i < leftSigs.count {
            switch context.script.version {
                case .legacy:
                result = context.transaction.checkSig(leftSigs[i], pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, script: context.script, opIdx: context.operationIndex)
                case .witnessV0:
                result = context.transaction.checkSigV0(leftSigs[i], pubKey: pubKey, inIdx: context.inputIndex, prevOut: context.previousOutput, script: context.script, opIdx: context.operationIndex)
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
