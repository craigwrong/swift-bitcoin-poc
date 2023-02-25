import Foundation

public extension Tx {
    
    func signedWitnessV1(privateKey: Data, publicKey: Data, inputIndex: Int, previousTxOuts: [Tx.Out], sigHashType: SigHashType) -> Tx {
        
        let preImage = signatureMessageV1(inputIndex: inputIndex, previousTxOuts: previousTxOuts, sigHashType: sigHashType, extFlag: 0) // TODO: Produce ext_flag
        let preImageHash = taggedHash(tag: "TagSighash", payload: sigHashType.data + preImage)
        
        let aux = getRandBytes(32)
        let signature = signSchnorr(message: preImageHash, secretKey: privateKey, merkleRoot: .none, aux: aux) + (sigHashType == .default ? Data() : sigHashType.data)
        
        // TODO: this is only for keyPath spending
        var newWitnesses = [Witness]()
        ins.enumerated().forEach { index, _ in
            if index == inputIndex {
                newWitnesses.append(.init(stack: [
                    signature
                ]))
            } else {
                newWitnesses.append(.init(stack: []))
            }
        }
        return .init(version: version, ins: ins, outs: outs, witnessData: newWitnesses, lockTime: lockTime)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    func signatureMessageV1(inputIndex: Int, previousTxOuts: [Tx.Out], sigHashType originalSigHashType: SigHashType, extFlag: UInt8) -> Data {
        
        precondition(previousTxOuts.count == ins.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        
        let sigHashType = originalSigHashType == .default ? SigHashType.all : originalSigHashType
        
        precondition(!sigHashType.isSingle || inputIndex < outs.count, "For single hash type, the selected input needs to have a matching output.")

        // Control:
        // hash_type (1).
        let controlData = sigHashType.data
        
        // Transaction data:
        // nVersion (4): the nVersion of the transaction.
        var transactionData = version.data
        // nLockTime (4): the nLockTime of the transaction.
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }
        transactionData.append(lockTimeData)
        
        //If the hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
        if !sigHashType.isAnyCanPay {
            // sha_prevouts (32): the SHA256 of the serialization of all input outpoints.
            let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
            let shaPrevouts = singleHash(prevouts)
            transactionData.append(shaPrevouts)
            // sha_amounts (32): the SHA256 of the serialization of all spent output amounts.
            let amounts = previousTxOuts.reduce(Data()) { $0 + $1.valueData}
            let shaAmounts = singleHash(amounts)
            transactionData.append(shaAmounts)
            // sha_scriptpubkeys (32): the SHA256 of all spent outputs' scriptPubKeys, serialized as script inside CTxOut.
            let scriptPubKeys = previousTxOuts.reduce(Data()) { $0 + $1.scriptPubKey.data(includeLength: false) } // TODO: Check that script serialization does not need to be prefixed with its length
            let shaScriptPubKeys = singleHash(scriptPubKeys)
            transactionData.append(shaScriptPubKeys)
            // sha_sequences (32): the SHA256 of the serialization of all input nSequence.
            let sequences = ins.reduce(Data()) { $0 + $1.sequenceData }
            let shaSequences = singleHash(sequences)
            transactionData.append(shaSequences)
        }
        // If hash_type & 3 does not equal SIGHASH_NONE or SIGHASH_SINGLE:
        if !sigHashType.isNone && !sigHashType.isSingle {
            // sha_outputs (32): the SHA256 of the serialization of all outputs in CTxOut format.
            let outputs = outs.reduce(Data()) { $0 + $1.data }
            let shaOutputs = singleHash(outputs)
            transactionData.append(shaOutputs)
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
        var inputData = Data()
        let originalWitnessStack = witnessData[inputIndex].stack // TODO: Check this witness stack is the original.
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
            let outpoint = ins[inputIndex].prevoutData
            inputData.append(outpoint)
            // amount (8): value of the previous output spent by this input.
            let amount = previousTxOuts[inputIndex].valueData
            inputData.append(amount)
            // scriptPubKey (35): scriptPubKey of the previous output spent by this input, serialized as script inside CTxOut. Its size is always 35 bytes.
            let scriptPubKey = previousTxOuts[inputIndex].scriptPubKey.data(includeLength: false)
            inputData.append(scriptPubKey)
            // nSequence (4): nSequence of this input.
            let sequence = withUnsafeBytes(of: ins[inputIndex].sequence) { Data($0) }
            inputData.append(sequence)
        } else { // If hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
            // input_index (4): index of this input in the transaction input vector. Index of the first input is 0.
            let inputIndexData = withUnsafeBytes(of: UInt32(inputIndex)) { Data($0) }
            inputData.append(inputIndexData)
        }
        //If an annex is present (the lowest bit of spend_type is set):
        if annexPresent == 1 {
            //sha_annex (32): the SHA256 of (compact_size(size of annex) || annex), where annex includes the mandatory 0x50 prefix.
            guard let annex = originalWitnessStack.last else {
                fatalError("Annex is supposed to be present.")
            }
            // TODO: Review and make sure it includes the varInt prefix (length)
            let shaAnnex = singleHash(annex)
            inputData.append(shaAnnex)
        }
        
        //Data about this output:
        //If hash_type & 3 equals SIGHASH_SINGLE:
        var outputData = Data()
        if sigHashType.isSingle {
            //sha_single_output (32): the SHA256 of the corresponding output in CTxOut format.
            let shaSingleOutput = singleHash(outs[inputIndex].data)
            outputData.append(shaSingleOutput)
        }
        
        return controlData + transactionData + inputData + outputData
    }
}
