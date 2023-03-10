import Foundation

public extension Tx {
    
    func checkSigV1(_ sig: Data, pubKey: Data, inIdx: Int, prevOuts: [Tx.Out], extFlag: UInt8) -> Bool {
        var sig = sig
        let sigHashType: SigHashType?
        if sig.count == 65, let hashTypeRaw = sig.popLast(), let hashType = SigHashType(rawValue: hashTypeRaw) {
            sigHashType = hashType
        } else {
            sigHashType = SigHashType?.none
        }
        let sigHash = sigHashV1(inIdx: inIdx, prevOuts: prevOuts, sigHashType: sigHashType, extFlag: extFlag)
        let result = verifySchnorr(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
