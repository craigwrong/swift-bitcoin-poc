import Foundation

public extension Tx {
    
    func checkSigV0(_ hashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptV0, opIdx: Int) -> Bool {
        var sig = hashType
        guard let hashTypeRaw = sig.popLast(), let hashType = HashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
