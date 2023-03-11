import Foundation

public extension Tx {
    
    func signedV1(privKey: Data, pubKey: Data, sigHashType: SigHashType?, inIdx: Int, prevOuts: [Tx.Out]) -> Tx {
        
        let sigHash = sigHashV1(sigHashType, inIdx: inIdx, prevOuts: prevOuts)
        let aux = getRandBytes(32)
        
        let sigHashTypeSuffix: Data
        if let sigHashType {
            sigHashTypeSuffix = sigHashType.data
        } else {
            sigHashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sigHash, privKey: privKey, merkleRoot: .none, aux: aux) + sigHashTypeSuffix
        
        // TODO: this is only for keyPath spending
        var newWitnesses = [Witness]()
        ins.enumerated().forEach { i, _ in
            if i == inIdx {
                newWitnesses.append(.init(stack: [
                    sig
                ]))
            } else {
                newWitnesses.append(.init(stack: []))
            }
        }
        return .init(version: version, ins: ins, outs: outs, witnessData: newWitnesses, lockTime: lockTime)
    }

    func sigHashV1(_ type: SigHashType?, inIdx: Int, prevOuts: [Tx.Out]) -> Data {
        let sigMsg = sigMsgV1(sigHashType: type, inIdx: inIdx, prevOuts: prevOuts, extFlag: 0)
        // TODO: Produce ext_flag for either sigversion taproot (ext_flag = 0) or tapscript (ext_flag = 1). Also produce key_version ( key_version = 0) for BIP 342 signatures.
        
        return taggedHash(tag: "TapSighash", payload: sigMsg)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    /// https://bitcoin.stackexchange.com/questions/115328/how-do-you-calculate-a-taproot-sighash
    func sigMsgV1(sigHashType: SigHashType?, inIdx: Int, prevOuts: [Tx.Out], extFlag: UInt8) -> Data {
        
        precondition(prevOuts.count == ins.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        precondition(!sigHashType.isSingle || inIdx < outs.count, "For single hash type, the selected input needs to have a matching output.")

        // Epoch:
        // epoch (0).
        let epochData = withUnsafeBytes(of: UInt8(0)) { Data($0) }
        
        // Control:
        // hash_type (1).
        let controlData = sigHashType.data
        
        // Transaction data:
        // nVersion (4): the nVersion of the transaction.
        var txData = version.data
        // nLockTime (4): the nLockTime of the transaction.
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }
        txData.append(lockTimeData)
        
        //If the hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
        if !sigHashType.isAnyCanPay {
            // sha_prevouts (32): the SHA256 of the serialization of all input outpoints.
            let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
            let shaPrevouts = sha256(prevouts)
            txData.append(shaPrevouts)
            // sha_amounts (32): the SHA256 of the serialization of all spent output amounts.
            let amounts = prevOuts.reduce(Data()) { $0 + $1.valueData}
            let shaAmounts = sha256(amounts)
            txData.append(shaAmounts)
            // sha_scriptpubkeys (32): the SHA256 of all spent outputs' scriptPubKeys, serialized as script inside CTxOut.
            let scriptPubKeys = prevOuts.reduce(Data()) { $0 + $1.scriptPubKey.data(includeLength: false) } // TODO: Check that script serialization does not need to be prefixed with its length
            let shaScriptPubKeys = sha256(scriptPubKeys)
            txData.append(shaScriptPubKeys)
            // sha_sequences (32): the SHA256 of the serialization of all input nSequence.
            let sequences = ins.reduce(Data()) { $0 + $1.sequenceData }
            let shaSequences = sha256(sequences)
            txData.append(shaSequences)
        }
        // If hash_type & 3 does not equal SIGHASH_NONE or SIGHASH_SINGLE:
        if !sigHashType.isNone && !sigHashType.isSingle {
            // sha_outputs (32): the SHA256 of the serialization of all outputs in CTxOut format.
            let outsData = outs.reduce(Data()) { $0 + $1.data }
            let shaOuts = sha256(outsData)
            txData.append(shaOuts)
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
        var inputData = Data()
        let originalWitnessStack = witnessData[inIdx].stack // TODO: Check this witness stack is the original.
        let firstByteOfLastElement: UInt8?
        if let lastElement = originalWitnessStack.last, lastElement.count > 3 {
            firstByteOfLastElement = lastElement[1]
        } else {
            firstByteOfLastElement = .none
        }
        let annexPresent: UInt8 = originalWitnessStack.count > 1 && firstByteOfLastElement == 0x50 ? 1 : 0
        let spendType = (extFlag * 2) + annexPresent
        inputData.append(spendType)
        
        // If hash_type & 0x80 equals SIGHASH_ANYONECANPAY:
        if sigHashType.isAnyCanPay {
            // outpoint (36): the COutPoint of this input (32-byte hash + 4-byte little-endian).
            let outpoint = ins[inIdx].prevoutData
            inputData.append(outpoint)
            // amount (8): value of the previous output spent by this input.
            let amount = prevOuts[inIdx].valueData
            inputData.append(amount)
            // scriptPubKey (35): scriptPubKey of the previous output spent by this input, serialized as script inside CTxOut. Its size is always 35 bytes.
            let scriptPubKey = prevOuts[inIdx].scriptPubKey.data(includeLength: false)
            inputData.append(scriptPubKey)
            // nSequence (4): nSequence of this input.
            let sequence = withUnsafeBytes(of: ins[inIdx].sequence) { Data($0) }
            inputData.append(sequence)
        } else { // If hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
            // input_index (4): index of this input in the transaction input vector. Index of the first input is 0.
            let inputIndexData = withUnsafeBytes(of: UInt32(inIdx)) { Data($0) }
            inputData.append(inputIndexData)
        }
        //If an annex is present (the lowest bit of spend_type is set):
        if annexPresent == 1 {
            //sha_annex (32): the SHA256 of (compact_size(size of annex) || annex), where annex includes the mandatory 0x50 prefix.
            guard let annex = originalWitnessStack.last else {
                fatalError("Annex is supposed to be present.")
            }
            // TODO: Review and make sure it includes the varInt prefix (length)
            let shaAnnex = sha256(annex)
            inputData.append(shaAnnex)
        }
        
        //Data about this output:
        //If hash_type & 3 equals SIGHASH_SINGLE:
        var outputData = Data()
        if sigHashType.isSingle {
            //sha_single_output (32): the SHA256 of the corresponding output in CTxOut format.
            let shaSingleOutput = sha256(outs[inIdx].data)
            outputData.append(shaSingleOutput)
        }
        
        return epochData + controlData + txData + inputData + outputData
    }
}
