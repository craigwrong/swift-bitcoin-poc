import Foundation

func opCheckMultiSig(_ stack: inout [Data], context: ExecutionContext) throws {
    let (n, pubKeys, m, sigs) = try getCheckMultiSigParams(&stack)
    precondition(m <= n)
    precondition(pubKeys.count == n)
    precondition(sigs.count == m)
    precondition(context.version == .legacy || context.version == .witnessV0)
    var leftPubKeys = pubKeys
    var leftSigs = sigs
    while leftPubKeys.count > 0 && leftSigs.count > 0 {
        let pubKey = leftPubKeys.removeFirst()
        var result = false
        var i = 0
        while i < leftSigs.count {
            switch context.version {
                case .legacy:
                result = context.tx.checkSig(leftSigs[i], pubKey: pubKey, inIdx: context.inIdx, prevOut: context.prevOut, script: context.script, opIdx: context.opIdx)
                case .witnessV0:
                result = context.tx.checkSigV0(leftSigs[i], pubKey: pubKey, inIdx: context.inIdx, prevOut: context.prevOut, script:  context.script, opIdx: context.opIdx)
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
    let result = leftSigs.count == 0
    stack.pushInt(result ? 1 : 0)
}
