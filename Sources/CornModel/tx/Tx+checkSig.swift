import Foundation

public extension Tx {
    
    func checkSig(_ hashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptLegacy, opIdx: Int) -> Bool {
        var sig = hashType
        guard let rawValue = sig.popLast(), let hashType = HashType(rawValue: rawValue) else {
            preconditionFailure()
        }
        let sigHash = sigHash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
