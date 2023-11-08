import Foundation

extension Transaction {
    
    func checkSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutput: Output, scriptCode: Data) -> Bool {
        precondition(extendedSignature.count > 69, "Signature too short or missing hash type suffix.")
        precondition(extendedSignature.count < 72, "Signature too long.")
        var sigTmp = extendedSignature
        guard let rawValue = sigTmp.popLast(), let sighashType = SighashType(rawValue: rawValue) else {
            preconditionFailure()
        }
        let sig = sigTmp
        let sighash = signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput, scriptCode: scriptCode)
        let result = verifyECDSA(sig: sig, msg: sighash, publicKey: publicKey)
        return result
    }
    
    func checkSegwitSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutputs: Output, scriptCode: Data) -> Bool {
        var sigTmp = extendedSignature
        guard let sighashTypeRaw = sigTmp.popLast(), let sighashType = SighashType(rawValue: sighashTypeRaw) else {
            fatalError()
        }
        let sig = sigTmp
        let sighash = segwitSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutputs, scriptCode: scriptCode)
        let result = verifyECDSA(sig: sig, msg: sighash, publicKey: publicKey)
        return result
    }
    
    func checkTaprootSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutputs: [Output], extFlag: UInt8 = 0, tapscriptExtension: TapscriptExtension? = .none) -> Bool {
        // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig), where Verify is defined in BIP340.
        // If the sig is 65 bytes long, return sig[64] ≠ 0x00 and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
        // Otherwise, fail.
        var sigTmp = extendedSignature
        let sighashType: SighashType?
        if sigTmp.count == 65, let rawValue = sigTmp.popLast(), let maybeHashType = SighashType(rawValue: rawValue) {
            sighashType = maybeHashType
        } else if sigTmp.count == 64 {
            sighashType = SighashType?.none
        } else {
            return false
        }
        let sig = sigTmp
        
        var txCopy = self
        var cache = SighashCache() // TODO: Hold on to cache.
        let sighash = txCopy.taprootSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutputs: previousOutputs, tapscriptExtension: tapscriptExtension, sighashCache: &cache)
        let result = verifySchnorr(sig: sig, msg: sighash, publicKey: publicKey)
        return result
    }
}
