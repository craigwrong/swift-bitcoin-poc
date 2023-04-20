import Foundation

public extension Tx {
    
    func checkSigV1(_ sig: Data, pubKey: Data, inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig), where Verify is defined in BIP340.
        // If the sig is 65 bytes long, return sig[64] ≠ 0x00 and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
        // Otherwise, fail.
        var sig = sig
        let sigHashType: SigHashType?
        if sig.count == 65, let rawValue = sig.popLast(), let hashType = SigHashType(rawValue: rawValue) {
            sigHashType = hashType
        } else if sig.count == 64 {
            sigHashType = SigHashType?.none
        } else {
            return false
        }
        let sigHash = sigHashV1(sigHashType, inIdx: inIdx, prevOuts: prevOuts)
        let result = verifySchnorr(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
