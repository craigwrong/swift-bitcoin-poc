import Foundation

public extension Tx {
    
    func checkSigV1(_ sig: Data, pubKey: Data, inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
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

        // TODO: Produce ext_flag for either sigversion taproot (ext_flag = 0) or tapscript (ext_flag = 1)
        let extFlag = UInt8(0)
        // TODO: produce key_version ( key_version = 0) for BIP 342 signatures.
        
        // Annex extraction
        guard let originalWitnessStack = ins[inIdx].witness else {
            fatalError()
        }
        // TODO: Check this witness stack is the original (and not a modified version by the execution of OP_CHECKSIG)
        
        let firstByteOfLastElement: UInt8?
        // TODO: Investigate why we were using `lastElement.count > 3` and `lastElement[1]` in the first place
        // if let lastElement = originalWitnessStack.last, lastElement.count > 3 { firstByteOfLastElement = lastElement[1] … }
        if let lastElement = originalWitnessStack.last, lastElement.count > 0 {
            firstByteOfLastElement = lastElement[0]
        } else {
            firstByteOfLastElement = .none
        }
        let annexPresent = originalWitnessStack.count > 1 && firstByteOfLastElement == 0x50
        let annex: Data?
        if let lastElement = originalWitnessStack.last, annexPresent {
            annex = lastElement
        } else {
            annex = .none
        }
        
        var txCopy = self
        var cache = SigMsgV1Cache?.none // TODO: Use cache.
        let sigHash = txCopy.sigHashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, extFlag: extFlag, annex: annex, cache: &cache)
        let result = verifySchnorr(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
}
