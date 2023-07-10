import Foundation

extension Transaction {

    public func verify(prevOuts: [Transaction.Output]) -> Bool {
        for i in inputs.indices {
            do {
                try verify(inIdx: i, prevOuts: prevOuts)
            } catch {
                return false
            }
        }
        return true
    }
    
    func verify(inIdx: Int, prevOuts: [Transaction.Output]) throws {
        let input = inputs[inIdx]
        let prevOut = prevOuts[inIdx]

        let scriptSig = input.script
        let scriptPubKey = prevOut.script
        
        let scriptPubKey2: SerializedScript
        switch scriptPubKey.outputType {
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown:
            var stack = [Data]()
            try scriptSig.run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
            try scriptPubKey.run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
            return
        case .scriptHash:
            var stack = [Data]()
            guard
                let parsedScriptSig = scriptSig.parsed else {
                throw ScriptError.invalidScript
            }
            guard
                let op = parsedScriptSig.operations.last else {
                throw ScriptError.invalidScript
            }
            try ParsedScript([op]).run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
            try scriptPubKey.run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
            guard case let .pushBytes(redeemScriptRaw) = op else {
                fatalError()
            }
            // Looks like we need to parse the redeem script first in order to performe some checks like verifying the number of operations.
            guard let redeemScript = ParsedScript(redeemScriptRaw) else {
                throw ScriptError.unparsableRedeemScript
            }
            switch(redeemScript.outputType) {
                case .nonStandard:
                    throw ScriptError.nonStandardScript
                case .witnessUnknown:
                    throw ScriptError.unknownWitnessVersion
                case .witnessV0KeyHash, .witnessV0ScriptHash:
                    // Redeem script is a p2wkh or p2wsh, just need to verify there are no more operations
                    guard parsedScriptSig.operations.count == 1 else {
                        // The scriptSig must be exactly a push of the BIP16 redeemScript or validation fails. ("P2SH witness program")
                        throw ScriptError.invalidScript
                    }
                    scriptPubKey2 = .init(redeemScriptRaw)
                default:
                    var stack2 = [Data]()
                    try ParsedScript(parsedScriptSig.operations.dropLast()).run(&stack2, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
                    try redeemScript.run(&stack2, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
                    return
            }
        case .witnessV0KeyHash, .witnessV0ScriptHash, .witnessV1TapRoot:
            guard scriptSig.isEmpty else {
                // The scriptSig must be exactly empty or validation fails. ("native witness program")
                throw ScriptError.invalidScript
            }
            scriptPubKey2 = scriptPubKey
        }
        switch scriptPubKey2.outputType {
        case .witnessV0KeyHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the hash of the key
            guard var stack = inputs[inIdx].witness?.elements else {
                fatalError()
            }
            try ParsedScript.makeP2WPKH(witnessProgram).run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV0ScriptHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the sha256 of the witness script
            guard var stack = inputs[inIdx].witness?.elements, let witnessScriptRaw = stack.popLast() else {
                fatalError()
            }
            guard sha256(witnessScriptRaw) == witnessProgram else {
                throw ScriptError.invalidScript
            }
            let witnessScript = SerializedScript(witnessScriptRaw, version: .witnessV0)
            try witnessScript.run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV1TapRoot:
            // A Taproot output is a native SegWit output (see BIP141) with version number 1, and a 32-byte witness program. The following rules only apply when such an output is being spent. Any other outputs, including version 1 outputs with lengths other than 32 bytes, remain unencumbered.

            // P2SH-wrapped version 1 outputs, remain unencumbered. Not needed.
            // if prevOut.scriptPubKey.outputType == .scriptHash { return true }

            // Guard not strictly needed as `outputKey` (aka witnessProgram) would be recognized as non-standard and execute normally
            // guard scriptPubKey2.witnessProgram.count == 32 else { return true }

            guard let witness = inputs[inIdx].witness else { preconditionFailure() }
            
            var stack = witness.elements
            
            // Fail if the witness stack has 0 elements.
            if stack.count == 0 { throw ScriptError.invalidScript }
            
            let outputKey = scriptPubKey2.witnessProgram // In this case it is the key (aka taproot output key q)
                        
            // this last element is called annex a and is removed from the witness stack
            if witness.taprootAnnex != .none { stack.removeLast() }
            
            // If there is exactly one element left in the witness stack, key path spending is used:
            if stack.count == 1 {
                // If the sig is 64 bytes long, return Verify(q, hashTapSighash(0x00 || SigMsg(0x00, 0)), sig)[20], where Verify is defined in BIP340.
                // If the sig is 65 bytes long, return sig[64] ≠ 0x00[21] and Verify(q, hashTapSighash(0x00 || SigMsg(sig[64], 0)), sig[0:64]).
                // Otherwise, fail[22].
                guard checkSigV1(stack[0], pubKey: outputKey, inIdx: inIdx, prevOuts: prevOuts) else {
                    throw ScriptError.invalidScript
                }
                return
            }
            
            // If there are at least two witness elements left, script path spending is used:
            // The last stack element is called the control block c
            let control = stack.removeLast()

            // control block c, and must have length 33 + 32m, for a value of m that is an integer between 0 and 128, inclusive. Fail if it does not have such a length.
            guard control.count >= 33 && (control.count - 33) % 32 == 0 && (control.count - 33) / 32 < 129 else {
                throw ScriptError.invalidScript
            }

            // Call the second-to-last stack element s, the script.
            // The script as defined in BIP341 (i.e., the penultimate witness stack element after removing the optional annex) is called the tapscript
            let tapscriptData = stack.removeLast()

            // Let p = c[1:33] and let P = lift_x(int(p)) where lift_x and [:] are defined as in BIP340. Fail if this point is not on the curve.
            // q is referred to as taproot output key and p as taproot internal key.
            let internalKey = control[1...32]
            
            // Fail if this point is not on the curve.
            guard validatePubKey(internalKey) else { throw ScriptError.invalidScript }

            // Let v = c[0] & 0xfe and call it the leaf version
            let leafVersion = control[0] & 0xfe
            
            // BIP 342 Tapscript - https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki
            // The leaf version is 0xc0 (i.e. the first byte of the last witness element after removing the optional annex is 0xc0 or 0xc1), marking it as a tapscript spend.
            guard leafVersion == 0xc0 else { return }

            // Let k0 = hashTapLeaf(v || compact_size(size of s) || s); also call it the tapleaf hash.
            let tapLeafHash = taggedHash(tag: "TapLeaf", payload: Data([leafVersion]) + tapscriptData.varLenData)

            // Compute the Merkle root from the leaf and the provided path.
            let merkleRoot = computeMerkleRoot(controlBlock: control, tapLeafHash: tapLeafHash)
            
            // Verify that the output pubkey matches the tweaked internal pubkey, after correcting for parity.
            let parity = (control[0] & 0x01) != 0
            guard checkTapTweak(pubKey: internalKey, tweakedKey: outputKey, merkleRoot: merkleRoot, parity: parity) else {
                throw ScriptError.invalidScript
            }

            let tapscript = SerializedScript(tapscriptData, version: .witnessV1)
            try tapscript.run(&stack, transaction: self, inIdx: inIdx, prevOuts: prevOuts, tapLeafHash: tapLeafHash)
        default:
            fatalError() // Should never reach here
        }
    }
}
