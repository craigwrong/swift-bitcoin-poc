import Foundation

extension Transaction {

    // -MARK: Legacy Bitcoin SCRIPT system
    
    /// Signature hash for legacy inputs.
    /// - Parameters:
    ///   - hashType: Signature hash type.
    ///   - inIdx: Transaction input index.
    ///   - prevOut: Previous unspent transaction output corresponding to the transaction input being signed/verified.
    ///   - scriptCode: The executed script. For Pay-to-Script-Hash outputs it should correspond to the redeem script.
    /// - Returns: A hash value for use while either signing or verifying a transaction input.
    func signatureHash(sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output, scriptCode: Data) -> Data {
        let sigMsg = signatureMessage(sighashType: sighashType, inputIndex: inputIndex, scriptCode: scriptCode)
        return hash256(sigMsg)
    }
    
    /// Aka sigMsg. See https://en.bitcoin.it/wiki/OP_CHECKSIG
    func signatureMessage(sighashType: SighashType, inputIndex: Int, scriptCode: Data) -> Data {
        var newIns = [Transaction.Input]()
        if sighashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newIns.append(.init(outpoint: inputs[inputIndex].outpoint, sequence: inputs[inputIndex].sequence, script: .init(scriptCode)))
        } else {
            inputs.enumerated().forEach { i, input in
                newIns.append(.init(
                    outpoint: input.outpoint,
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: i == inputIndex || sighashType.isAll ? input.sequence : .initial,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    script: i == inputIndex ? .init(scriptCode) : .empty
                ))
            }
        }
        var newOuts: [Transaction.Output]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        if sighashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOuts = []
            
            outputs.enumerated().forEach { i, out in
                guard i <= inputIndex else {
                    return
                }
                if i == inputIndex {
                    newOuts.append(out)
                } else if i < inputIndex {
                    // Value is "long -1" which means UInt64(bitPattern: -1) aka UInt64.max
                    newOuts.append(.init(value: Amount.max, script: SerializedScript.empty))
                }
            }
            if inputIndex > outputs.endIndex {
                while newOuts.count < inputIndex + 1 {
                    // Note: The transaction that uses SIGHASH_SINGLE type of signature should not have more inputs than outputs. However if it does (because of the pre-existing implementation), it shall not be rejected, but instead for every "illegal" input (meaning: an input that has an index bigger than the maximum output index) the node should still verify it, though assuming the hash of 0000000000000000000000000000000000000000000000000000000000000001
                    
                    // From [https://en.bitcoin.it/wiki/BIP_0143]:
                    // In the original algorithm, a uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
                    
                    // newOuts.append(Data(repeating: 0, count: 255) + Data([0x01]))
                    // TODO: figure out how to add this serialized output to the message
                }
            }
        } else if sighashType.isNone {
            newOuts = []
        } else {
            newOuts = outputs
        }
        let txCopy = Transaction(
            version: version,
            locktime: locktime,
            inputs: newIns,
            outputs: newOuts
        )
        return txCopy.data + sighashType.data32
    }

    // -MARK: Segregated Witnes version 0 (SegWit)
    
    func segwitSignatureHash(sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output, scriptCode: Data) -> Data {
        hash256(segwitSignatureMessage(sighashType: sighashType, inputIndex: inputIndex, scriptCode: scriptCode, amount: previousOutput.value))
    }

    /// SegWit v0 signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#specification .
    func segwitSignatureMessage(sighashType: SighashType, inputIndex: Int, scriptCode: Data, amount: Amount) -> Data {
        //If the ANYONECANPAY flag is not set, hashPrevouts is the double SHA256 of the serialization of all input outpoints;
        // Otherwise, hashPrevouts is a uint256 of 0x0000......0000.
        var hashPrevouts: Data
        if sighashType.isAnyCanPay {
            hashPrevouts = Data(repeating: 0, count: 256)
        } else {
            let prevouts = inputs.reduce(Data()) { $0 + $1.outpoint.data }
            hashPrevouts = hash256(prevouts)
        }
        
        // If none of the ANYONECANPAY, SINGLE, NONE sighash type is set, hashSequence is the double SHA256 of the serialization of nSequence of all inputs;
        // Otherwise, hashSequence is a uint256 of 0x0000......0000.
        let hashSequence: Data
        if !sighashType.isAnyCanPay && !sighashType.isSingle && !sighashType.isNone {
            let sequence = inputs.reduce(Data()) {
                $0 + $1.sequence.data
            }
            hashSequence = hash256(sequence)
        } else {
            hashSequence = Data(repeating: 0, count: 256)
        }
        
        let outpointData = inputs[inputIndex].outpoint.data
        
        let scriptCodeData = scriptCode.varLenData
        
        let amountData = withUnsafeBytes(of: amount) { Data($0) }
        let sequenceData = inputs[inputIndex].sequence.data
        
        // If the sighash type is neither SINGLE nor NONE, hashOutputs is the double SHA256 of the serialization of all output amount (8-byte little endian) with scriptPubKey (serialized as scripts inside CTxOuts);
        // If sighash type is SINGLE and the input index is smaller than the number of outputs, hashOutputs is the double SHA256 of the output amount with scriptPubKey of the same index as the input;
        // Otherwise, hashOutputs is a uint256 of 0x0000......0000.[7]
        let hashOuts: Data
        if !sighashType.isSingle && !sighashType.isNone {
            let outsData = outputs.reduce(Data()) { $0 + $1.data }
            hashOuts = hash256(outsData)
        } else if sighashType.isSingle && inputIndex < outputs.count {
            hashOuts = hash256(outputs[inputIndex].data)
        } else {
            hashOuts = Data(repeating: 0, count: 256)
        }
        
        let remaindingData = sequenceData + hashOuts + locktime.data + sighashType.data32
        return version.data + hashPrevouts + hashSequence + outpointData + scriptCodeData + amountData + remaindingData
    }

    // -MARK: Segregated Witnes version 1 (TapRoot)

    mutating func taprootSignatureHash(sighashType: SighashType?, inputIndex: Int, previousOutputs: [Transaction.Output], tapscriptExtension: TapscriptExtension? = .none) -> Data {
        var cache = SighashCache()
        return taprootSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutputs: previousOutputs, tapscriptExtension: tapscriptExtension, sighashCache: &cache)
    }
    
    mutating func taprootSignatureHash(sighashType: SighashType?, inputIndex: Int, previousOutputs: [Transaction.Output], tapscriptExtension: TapscriptExtension? = .none, sighashCache: inout SighashCache) -> Data {
        var payload = taprootSignatureMessage(sighashType: sighashType, extFlag: tapscriptExtension == .none ? 0 : 1, inputIndex: inputIndex, previousOutputs: previousOutputs, sighashCache: &sighashCache)
        if let tapscriptExtension {
            payload += tapscriptExtension.data
        }
        return taggedHash(tag: "TapSighash", payload: payload)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    /// https://bitcoin.stackexchange.com/questions/115328/how-do-you-calculate-a-taproot-sighash
    func taprootSignatureMessage(sighashType: SighashType?, extFlag: UInt8 = 0, inputIndex: Int, previousOutputs: [Transaction.Output], sighashCache: inout SighashCache) -> Data {
        
        precondition(previousOutputs.count == inputs.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        precondition(!sighashType.isSingle || inputIndex < outputs.count, "For single hash type, the selected input needs to have a matching output.")

        // (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
        let annex = inputs[inputIndex].witness?.taprootAnnex

        // Epoch:
        // epoch (0).
        let epochData = withUnsafeBytes(of: UInt8(0)) { Data($0) }
        
        // Control:
        // hash_type (1).
        let controlData = sighashType.data
        
        // Transaction data:
        // nVersion (4): the nVersion of the transaction.
        var txData = version.data
        // nLockTime (4): the nLockTime of the transaction.
        txData.append(locktime.data)
        
        //If the hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
        if !sighashType.isAnyCanPay {
            // sha_prevouts (32): the SHA256 of the serialization of all input outpoints.
            let shaPrevouts: Data
            if let cached = sighashCache.shaPrevouts {
                shaPrevouts = cached
            } else {
                let prevouts = inputs.reduce(Data()) { $0 + $1.outpoint.data }
                shaPrevouts = sha256(prevouts)
                sighashCache.shaPrevouts = shaPrevouts
            }
            sighashCache.shaPrevoutsUsed = true
            txData.append(shaPrevouts)

            // sha_amounts (32): the SHA256 of the serialization of all spent output amounts.
            let shaAmounts: Data
            if let cached = sighashCache.shaAmounts {
                shaAmounts = cached
            } else {
                let amounts = previousOutputs.reduce(Data()) { $0 + $1.valueData }
                shaAmounts = sha256(amounts)
                sighashCache.shaAmounts = shaAmounts
            }
            sighashCache.shaAmountsUsed = true
            txData.append(shaAmounts)
            
            // sha_scriptpubkeys (32): the SHA256 of all spent outputs' scriptPubKeys, serialized as script inside CTxOut.
            let shaScriptPubKeys: Data
            if let cached = sighashCache.shaScriptPubKeys {
                shaScriptPubKeys = cached
            } else {
                let scriptPubKeys = previousOutputs.reduce(Data()) { $0 + $1.script.prefixedData }
                shaScriptPubKeys = sha256(scriptPubKeys)
                sighashCache.shaScriptPubKeys = shaScriptPubKeys
            }
            sighashCache.shaScriptPubKeysUsed = true
            txData.append(shaScriptPubKeys)

            // sha_sequences (32): the SHA256 of the serialization of all input nSequence.
            let shaSequences: Data
            if let cached = sighashCache.shaSequences {
                shaSequences = cached
            } else {
                let sequences = inputs.reduce(Data()) { $0 + $1.sequence.data }
                shaSequences = sha256(sequences)
                sighashCache.shaSequences = shaSequences
            }
            sighashCache.shaSequencesUsed = true
            txData.append(shaSequences)
        } else {
            sighashCache.shaPrevoutsUsed = false
            sighashCache.shaAmountsUsed = false
            sighashCache.shaScriptPubKeysUsed = false
            sighashCache.shaSequencesUsed = false
        }
        
        // If hash_type & 3 does not equal SIGHASH_NONE or SIGHASH_SINGLE:
        if !sighashType.isNone && !sighashType.isSingle {
        // sha_outputs (32): the SHA256 of the serialization of all outputs in CTxOut format.
        let shaOuts: Data
            if let cached = sighashCache.shaOuts {
                shaOuts = cached
            } else {
                let outsData = outputs.reduce(Data()) { $0 + $1.data }
                shaOuts = sha256(outsData)
                sighashCache.shaOuts = shaOuts
            }
            sighashCache.shaOutsUsed = true
            txData.append(shaOuts)
        } else {
            sighashCache.shaOutsUsed = false
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise
        var inputData = Data()
        let spendType = (extFlag * 2) + (annex == .none ? 0 : 1)
        inputData.append(spendType)
        
        // If hash_type & 0x80 equals SIGHASH_ANYONECANPAY:
        if sighashType.isAnyCanPay {
            // outpoint (36): the COutPoint of this input (32-byte hash + 4-byte little-endian).
            let outpoint = inputs[inputIndex].outpoint.data
            inputData.append(outpoint)
            // amount (8): value of the previous output spent by this input.
            let amount = previousOutputs[inputIndex].valueData
            inputData.append(amount)
            // scriptPubKey (35): scriptPubKey of the previous output spent by this input, serialized as script inside CTxOut. Its size is always 35 bytes.
            let scriptPubKey = previousOutputs[inputIndex].script.prefixedData
            inputData.append(scriptPubKey)
            // nSequence (4): nSequence of this input.
            let sequence = inputs[inputIndex].sequence.data
            inputData.append(sequence)
        } else { // If hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
            // input_index (4): index of this input in the transaction input vector. Index of the first input is 0.
            let inputIndexData = withUnsafeBytes(of: UInt32(inputIndex)) { Data($0) }
            inputData.append(inputIndexData)
        }
        //If an annex is present (the lowest bit of spend_type is set):
        if let annex {
            //sha_annex (32): the SHA256 of (compact_size(size of annex) || annex), where annex includes the mandatory 0x50 prefix.
            // TODO: Review and make sure it includes the varInt prefix (length)
            let shaAnnex = sha256(annex)
            inputData.append(shaAnnex)
        }
        
        //Data about this output:
        //If hash_type & 3 equals SIGHASH_SINGLE:
        var outputData = Data()
        if sighashType.isSingle {
            //sha_single_output (32): the SHA256 of the corresponding output in CTxOut format.
            let shaSingleOutput = sha256(outputs[inputIndex].data)
            outputData.append(shaSingleOutput)
        }
        
        let sigMsg = epochData + controlData + txData + inputData + outputData
        return sigMsg
    }
}
