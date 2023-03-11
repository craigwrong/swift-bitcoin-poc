import Foundation

public extension Tx {
    
    func checkSig(_ sigSigHashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, scriptCode: Script, opIdx: Int) -> Bool {
        var sig = sigSigHashType
        guard let rawValue = sig.popLast(), let sigHashType = SigHashType(rawValue: rawValue) else {
            preconditionFailure()
        }
        let sigHash = sigHash(sigHashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
