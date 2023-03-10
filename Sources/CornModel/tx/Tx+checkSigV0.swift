import Foundation

public extension Tx {
    
    func checkSigV0(_ sigSigHashType: Data, pubKey: Data, inIdx: Int, scriptCode: Script, prevOut: Tx.Out) -> Bool {
        let scriptCode = Script.scriptCodeV0(hash160(pubKey))
        
        var sig = sigSigHashType
        guard let hashTypeRaw = sig.popLast(), let sigHashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHashV0(inIdx: inIdx, scriptCode: scriptCode, amount: prevOut.value, sigHashType: sigHashType)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
