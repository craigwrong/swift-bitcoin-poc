import Foundation

public extension Tx {
    
    func checkSigV0(_ sigSigHashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptV0, opIdx: Int) -> Bool {
        var sig = sigSigHashType
        guard let hashTypeRaw = sig.popLast(), let sigHashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHashV0(sigHashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
