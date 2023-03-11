import Foundation

public extension Tx {
    
    func checkSigV1(_ sig: Data, pubKey: Data, inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        var sig = sig
        let sigHashType: SigHashType?
        if sig.count == 65, let rawValue = sig.popLast(), let hashType = SigHashType(rawValue: rawValue) {
            sigHashType = hashType
        } else {
            sigHashType = SigHashType?.none
        }
        let sigHash = sigHashV1(sigHashType, inIdx: inIdx, prevOuts: prevOuts)
        let result = verifySchnorr(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
