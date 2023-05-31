import Foundation
public extension Tx {
    func verify(prevOuts: [Tx.Out]) -> Bool {
        ins.indices.reduce(true) { result, i in
            result && verify(inIdx: i, prevOuts: prevOuts)
        }
    }
    
    func verify(inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        let input = ins[inIdx]
        let prevOut = prevOuts[inIdx]
        let scriptPubKey = prevOut.scriptPubKey
        
        let scriptPubKey2: ScriptLegacy
        switch prevOut.scriptPubKey.scriptType {
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown:
            var stack = [Data]()
            guard let scriptSig = input.scriptSig, scriptSig.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts) else {
                return false
            }
            return prevOut.scriptPubKey.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .scriptHash:
            var stack = [Data]()
            guard
                let scriptSig = input.scriptSig, let op = scriptSig.ops.last,
                ScriptLegacy([op]).run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts),
                prevOut.scriptPubKey.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
            else {
                return false
            }
            guard let lastOp = scriptSig.ops.last, case let .pushBytes(redeemScriptRaw) = lastOp else {
                fatalError()
            }
            let redeemScript = ScriptLegacy(redeemScriptRaw)
            if redeemScript.scriptType != .witnessV0KeyHash && redeemScript.scriptType != .witnessV0ScriptHash {
                var stack2 = [Data]()
                guard
                    ScriptLegacy(scriptSig.ops.dropLast()).run(stack: &stack2, tx: self, inIdx: inIdx, prevOuts: prevOuts)
                else {
                    return false
                }
                return redeemScript.run(stack: &stack2, tx: self, inIdx: inIdx, prevOuts: prevOuts)
            }
            // Redeem script is a p2wkh or p2wsh, just need to verify there are no more operations
            guard scriptSig.ops.count == 1 else {
                // The scriptSig must be exactly a push of the BIP16 redeemScript or validation fails. ("P2SH witness program")
                return false
            }
            scriptPubKey2 = redeemScript
        case .witnessV0KeyHash, .witnessV0ScriptHash, .witnessV1TapRoot:
            guard input.scriptSig == .none else {
                // The scriptSig must be exactly empty or validation fails. ("native witness program")
                return false
            }
            scriptPubKey2 = scriptPubKey
        }
        switch scriptPubKey2.scriptType {
        case .witnessV0KeyHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the hash of the public key
            guard var stack = ins[inIdx].witness else {
                fatalError()
            }
            return ScriptV0.keyHashScript(witnessProgram).run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV0ScriptHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the sha256 of the witness script
            guard var stack = ins[inIdx].witness, let witnessScriptRaw = stack.popLast() else {
                fatalError()
            }
            guard sha256(witnessScriptRaw) == witnessProgram else {
                return false
            }
            let witnessScript = ScriptV0(witnessScriptRaw)
            return witnessScript.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV1TapRoot:
            // P2SH-wrapped version 1 outputs, remain unencumbered.
            if prevOut.scriptPubKey.scriptType == .scriptHash {
                return true
            }
            let witnessProgram = scriptPubKey2.witnessProgram
            
            // A Taproot output is a native SegWit output (see BIP141) with version number 1, and a 32-byte witness program. The following rules only apply when such an output is being spent. Any other outputs, including version 1 outputs with lengths other than 32 bytes, remain unencumbered.
            // Not needed as it would be recognized as non-standard and execute normally
            // if witnessProgram.count != 32 {
                // return true
            // }
            
            // Immutable copy to use as reference to the original witness stack
            guard let originalStack = ins[inIdx].witness else {
                fatalError()
            }
            
            // Fail if the witness stack has 0 elements.
            if originalStack.count == 0 {
                return false
            }

            // We will modify the stack
            var newStack = originalStack

            // If there are at least two witness elements, and the first byte of the last element is 0x50, this last element is called annex a
            let annex: Data?
            if originalStack.count > 1, let maybeAnnex = originalStack.last, maybeAnnex.isValidTaprootAnnex {
                annex = maybeAnnex
            } else {
                annex = .none
            }
            
            // this last element is called annex a and is removed from the witness stack
            if annex != .none {
                newStack.removeLast()
            }
            
            // If there is exactly one element left in the witness stack, key path spending is used:
            if newStack.count == 1 {
                let outputKey = scriptPubKey2.witnessProgram // In this case it is the public key (aka taproot output key q)
                // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig)[20], where Verify is defined in BIP340.
                // If the sig is 65 bytes long, return sig[64] ≠ 0x00[21] and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
                // Otherwise, fail[22].
                return ScriptV1.keyHashScript(outputKey).run(stack: &newStack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
            }
            
            // If there are at least two witness elements left, script path spending is used:
            
            // The last stack element is called the control block c
            let controlBlock = newStack.removeLast()

            // control block c, and must have length 33 + 32m, for a value of m that is an integer between 0 and 128[6], inclusive. Fail if it does not have such a length.
            
            // Call the second-to-last stack element s, the script.
            let script = newStack.removeLast()
            
            return false
            
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown, .scriptHash:
            fatalError()
        }
    }
}
