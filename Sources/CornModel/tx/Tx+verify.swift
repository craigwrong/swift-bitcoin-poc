import Foundation

extension Tx {

    public func verify(prevOuts: [Tx.Out]) -> Bool {
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
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the hash of the key
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
            // A Taproot output is a native SegWit output (see BIP141) with version number 1, and a 32-byte witness program. The following rules only apply when such an output is being spent. Any other outputs, including version 1 outputs with lengths other than 32 bytes, remain unencumbered.

            // P2SH-wrapped version 1 outputs, remain unencumbered. Not needed.
            // if prevOut.scriptPubKey.scriptType == .scriptHash { return true }

            // Guard not strictly needed as `outputKey` (aka witnessProgram) would be recognized as non-standard and execute normally
            // guard scriptPubKey2.witnessProgram.count == 32 else { return true }

            guard var stack = ins[inIdx].witness else { preconditionFailure() }
            
            // Fail if the witness stack has 0 elements.
            if stack.count == 0 { return false }
            
            let outputKey = scriptPubKey2.witnessProgram // In this case it is the key (aka taproot output key q)
                        
            // this last element is called annex a and is removed from the witness stack
            if ins[inIdx].taprootAnnex != .none { stack.removeLast() }
            
            // If there is exactly one element left in the witness stack, key path spending is used:
            if stack.count == 1 {
                // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig)[20], where Verify is defined in BIP340.
                // If the sig is 65 bytes long, return sig[64] ≠ 0x00[21] and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
                // Otherwise, fail[22].
                return checkSigV1(stack[0], pubKey: outputKey, inIdx: inIdx, prevOuts: prevOuts)
            }
            
            // If there are at least two witness elements left, script path spending is used:
            // The last stack element is called the control block c
            let control = stack.removeLast()

            // control block c, and must have length 33 + 32m, for a value of m that is an integer between 0 and 128, inclusive. Fail if it does not have such a length.
            guard control.count >= 33 && (control.count - 33) % 32 == 0 && (control.count - 33) / 32 < 129 else {
                return false
            }

            // Call the second-to-last stack element s, the script.
            // The script as defined in BIP341 (i.e., the penultimate witness stack element after removing the optional annex) is called the tapscript
            let tapscriptData = stack.removeLast()

            // Let p = c[1:33] and let P = lift_x(int(p)) where lift_x and [:] are defined as in BIP340. Fail if this point is not on the curve.
            // q is referred to as taproot output key and p as taproot internal key.
            let internalKey = control[1...33]
            
            // Fail if this point is not on the curve.
            guard validatePubKey(internalKey) else { return false }

            // Let v = c[0] & 0xfe and call it the leaf version
            let leafVersion = control[0] & 0xfe
            
            // BIP 342 Tapscript - https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki
            // The leaf version is 0xc0 (i.e. the first byte of the last witness element after removing the optional annex is 0xc0 or 0xc1), marking it as a tapscript spend.
            guard leafVersion == 0xc0 else { return true }

            // Let k0 = hashTapLeaf(v || compact_size(size of s) || s); also call it the tapleaf hash.
            let tapLeafHash = taggedHash(tag: "TapLeaf", payload: Data([leafVersion]) + tapscriptData.varLenData)

            // Compute the Merkle root from the leaf and the provided path.
            let merkleRoot = computeMerkleRoot(controlBlock: control, tapLeafHash: tapLeafHash)
            
            // Verify that the output pubkey matches the tweaked internal pubkey, after correcting for parity.
            let parity = (control[0] & 0x01) != 0
            guard checkTapTweak(pubKey: internalKey, tweakedKey: outputKey, merkleRoot: merkleRoot, parity: parity) else {
                return false
            }

            let tapscript = ScriptV1(tapscriptData, tapLeafHash: tapLeafHash)
            return tapscript.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        default:
            preconditionFailure()
        }
    }
}
