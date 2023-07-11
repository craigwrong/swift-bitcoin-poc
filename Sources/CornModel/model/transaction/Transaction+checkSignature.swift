import Foundation

extension Transaction {
    
    func checkSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutput: Transaction.Output, scriptCode: Data) -> Bool {
        precondition(extendedSignature.count > 69, "Signature too short or missing hash type suffix.")
        precondition(extendedSignature.count < 72, "Signature too long.")
        var sigTmp = extendedSignature
        guard let rawValue = sigTmp.popLast(), let hashType = SighashType(rawValue: rawValue) else {
            preconditionFailure()
        }
        let sig = sigTmp
        let sighash = signatureHash(sighashType: hashType, inputIndex: inputIndex, previousOutput: previousOutput, scriptCode: scriptCode)
        let result = verifyECDSA(sig: sig, msg: sighash, pubKey: publicKey)
        return result
    }
    
    func checkSegwitSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutputs: Transaction.Output, scriptCode: Data) -> Bool {
        var sigTmp = extendedSignature
        guard let hashTypeRaw = sigTmp.popLast(), let hashType = SighashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sig = sigTmp
        let sighash = segwitSignatureHash(sighashType: hashType, inputIndex: inputIndex, previousOutput: previousOutputs, scriptCode: scriptCode)
        let result = verifyECDSA(sig: sig, msg: sighash, pubKey: publicKey)
        return result
    }
    
    func checkTaprootSignature(extendedSignature: Data, publicKey: Data, inputIndex: Int, previousOutputs: [Transaction.Output], extFlag: UInt8 = 0, tapscriptExtension: TapscriptExtension? = .none) -> Bool {
        // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig), where Verify is defined in BIP340.
        // If the sig is 65 bytes long, return sig[64] ≠ 0x00 and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
        // Otherwise, fail.
        var sigTmp = extendedSignature
        let hashType: SighashType?
        if sigTmp.count == 65, let rawValue = sigTmp.popLast(), let maybeHashType = SighashType(rawValue: rawValue) {
            hashType = maybeHashType
        } else if sigTmp.count == 64 {
            hashType = SighashType?.none
        } else {
            return false
        }
        let sig = sigTmp
        
        var txCopy = self
        var cache = SighashCache() // TODO: Hold on to cache.
        let sighash = txCopy.taprootSignatureHash(sighashType: hashType, inputIndex: inputIndex, previousOutputs: previousOutputs, tapscriptExtension: tapscriptExtension, sighashCache: &cache)
        let result = verifySchnorr(sig: sig, msg: sighash, pubKey: publicKey)
        return result
    }
}
