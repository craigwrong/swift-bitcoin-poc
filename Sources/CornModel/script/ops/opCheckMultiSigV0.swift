import Foundation

func opCheckMultiSigV0(_ n: Int, _ m: Int, _ pubKeys: [Data], _ sigs: [Data], stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], scriptCode: [Op], opIdx: Int) -> Bool {
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
            result = tx.checkSigV0(leftSigs[i], pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], scriptCode: scriptCode, opIdx: opIdx)
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
    return true
}
