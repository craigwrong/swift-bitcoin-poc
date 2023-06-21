import Foundation

extension Transaction {
    
    func checkSig(_ sighashType: Data, pubKey: Data, inIdx: Int, prevOut: Transaction.Output, script: [Op], opIdx: Int) -> Bool {
        precondition(sighashType.count > 69, "Signature too short or missing hash type suffix.")
        precondition(sighashType.count < 72, "Signature too long.")
        var sig = sighashType
        guard let rawValue = sig.popLast(), let hashType = HashType(rawValue: rawValue) else {
            preconditionFailure()
        }
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: script, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sighash, pubKey: pubKey)
        return result
    }
    
    func checkSigV0(_ sighashType: Data, pubKey: Data, inIdx: Int, prevOut: Transaction.Output, script: [Op], opIdx: Int) -> Bool {
        var sig = sighashType
        guard let hashTypeRaw = sig.popLast(), let hashType = HashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sighash = sighashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: script, opIdx: opIdx)
        let result = verifyECDSA(sig: sig, msg: sighash, pubKey: pubKey)
        return result
    }
    
    func checkSigV1(_ sig: Data, pubKey: Data, inIdx: Int, prevOuts: [Transaction.Output], extFlag: UInt8 = 0, tapscriptExt: TapscriptExt? = .none) -> Bool {
        // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig), where Verify is defined in BIP340.
        // If the sig is 65 bytes long, return sig[64] ≠ 0x00 and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
        // Otherwise, fail.
        var sig = sig
        let hashType: HashType?
        if sig.count == 65, let rawValue = sig.popLast(), let maybeHashType = HashType(rawValue: rawValue) {
            hashType = maybeHashType
        } else if sig.count == 64 {
            hashType = HashType?.none
        } else {
            return false
        }
        
        var txCopy = self
        var cache = SighashCache() // TODO: Hold on to cache.
        let sighash = txCopy.sighashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, tapscriptExt: tapscriptExt, cache: &cache)
        let result = verifySchnorr(sig: sig, msg: sighash, pubKey: pubKey)
        return result
    }
}
