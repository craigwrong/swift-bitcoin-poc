import Foundation

public extension Tx {
    
    func checkSig(_ sigSigHashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, redeemScript: Script?) -> Bool {
        var sig = sigSigHashType
        guard let hashTypeRaw = sig.popLast(), let hashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHash(sigHashType: hashType, inIdx: inIdx, prevOut: prevOut, redeemScript: redeemScript)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
