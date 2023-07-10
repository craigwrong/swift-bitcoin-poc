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
    func sighash(_ hashType: HashType, inIdx: Int, prevOut: Transaction.Output, scriptCode: Data) -> Data {
        let sigMsg = sigMsg(hashType: hashType, inIdx: inIdx, subScript: scriptCode)
        return hash256(sigMsg)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func sigMsg(hashType: HashType, inIdx: Int, subScript: Data) -> Data {
        var newIns = [Transaction.Input]()
        if hashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newIns.append(.init(outpoint: inputs[inIdx].outpoint, sequence: inputs[inIdx].sequence, script: .init(subScript)))
        } else {
            inputs.enumerated().forEach { i, input in
                newIns.append(.init(
                    outpoint: input.outpoint,
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: i == inIdx || hashType.isAll ? input.sequence : .initial,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    script: i == inIdx ? .init(subScript) : .empty
                ))
            }
        }
        var newOuts: [Transaction.Output]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if hashType.isSingle && inIdx >= outputs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outputs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if hashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOuts = []
            
            outputs.enumerated().forEach { i, out in
                guard i <= inIdx else {
                    return
                }
                if i == inIdx {
                    newOuts.append(out)
                } else if i < inIdx {
                    // TODO: Verify that "long -1" means  UInt64(bitPattern: -1) aka UInt64.max
                    newOuts.append(.init(value: Amount.max, script: SerializedScript.empty))
                }
            }
            
        } else if hashType.isNone {
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
        return txCopy.data + hashType.data32
    }

    // -MARK: Segregated Witnes version 0 (SegWit)
    
    func sighashV0(_ hashType: HashType, inIdx: Int, prevOut: Transaction.Output, scriptCode: Data) -> Data {
        hash256(sigMsgV0(hashType: hashType, inIdx: inIdx, scriptCode: scriptCode, amount: prevOut.value))
    }

    /// SegWit v0 signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#specification .
    func sigMsgV0(hashType: HashType, inIdx: Int, scriptCode: Data, amount: Amount) -> Data {
        //If the ANYONECANPAY flag is not set, hashPrevouts is the double SHA256 of the serialization of all input outpoints;
        // Otherwise, hashPrevouts is a uint256 of 0x0000......0000.
        var hashPrevouts: Data
        if hashType.isAnyCanPay {
            hashPrevouts = Data(repeating: 0, count: 256)
        } else {
            let prevouts = inputs.reduce(Data()) { $0 + $1.outpoint.data }
            hashPrevouts = hash256(prevouts)
        }
        
        // If none of the ANYONECANPAY, SINGLE, NONE sighash type is set, hashSequence is the double SHA256 of the serialization of nSequence of all inputs;
        // Otherwise, hashSequence is a uint256 of 0x0000......0000.
        let hashSequence: Data
        if !hashType.isAnyCanPay && !hashType.isSingle && !hashType.isNone {
            let sequence = inputs.reduce(Data()) {
                $0 + $1.sequence.data
            }
            hashSequence = hash256(sequence)
        } else {
            hashSequence = Data(repeating: 0, count: 256)
        }
        
        let outpointData = inputs[inIdx].outpoint.data
        
        let scriptCodeData = scriptCode.varLenData
        
        let amountData = withUnsafeBytes(of: amount) { Data($0) }
        let sequenceData = inputs[inIdx].sequence.data
        
        // If the sighash type is neither SINGLE nor NONE, hashOutputs is the double SHA256 of the serialization of all output amount (8-byte little endian) with scriptPubKey (serialized as scripts inside CTxOuts);
        // If sighash type is SINGLE and the input index is smaller than the number of outputs, hashOutputs is the double SHA256 of the output amount with scriptPubKey of the same index as the input;
        // Otherwise, hashOutputs is a uint256 of 0x0000......0000.[7]
        let hashOuts: Data
        if !hashType.isSingle && !hashType.isNone {
            let outsData = outputs.reduce(Data()) { $0 + $1.data }
            hashOuts = hash256(outsData)
        } else if hashType.isSingle && inIdx < outputs.count {
            hashOuts = hash256(outputs[inIdx].data)
        } else {
            hashOuts = Data(repeating: 0, count: 256)
        }
        
        let remaindingData = sequenceData + hashOuts + locktime.data + hashType.data32
        return version.data + hashPrevouts + hashSequence + outpointData + scriptCodeData + amountData + remaindingData
    }

    // -MARK: Segregated Witnes version 1 (TapRoot)

    mutating func sighashV1(_ hashType: HashType?, inIdx: Int, prevOuts: [Transaction.Output], tapscriptExt: TapscriptExt? = .none) -> Data {
        var cache = SighashCache()
        return sighashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, tapscriptExt: tapscriptExt, cache: &cache)
    }
    
    mutating func sighashV1(_ hashType: HashType?, inIdx: Int, prevOuts: [Transaction.Output], tapscriptExt: TapscriptExt? = .none, cache: inout SighashCache) -> Data {
        var payload = sigMsgV1(hashType: hashType, extFlag: tapscriptExt == .none ? 0 : 1, inIdx: inIdx, prevOuts: prevOuts, cache: &cache)
        if let tapscriptExt {
            payload += tapscriptExt.data
        }
        return taggedHash(tag: "TapSighash", payload: payload)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    /// https://bitcoin.stackexchange.com/questions/115328/how-do-you-calculate-a-taproot-sighash
    func sigMsgV1(hashType: HashType?, extFlag: UInt8 = 0, inIdx: Int, prevOuts: [Transaction.Output], cache: inout SighashCache) -> Data {
        
        precondition(prevOuts.count == inputs.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        precondition(!hashType.isSingle || inIdx < outputs.count, "For single hash type, the selected input needs to have a matching output.")

        // (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
        let annex = inputs[inIdx].witness?.taprootAnnex

        // Epoch:
        // epoch (0).
        let epochData = withUnsafeBytes(of: UInt8(0)) { Data($0) }
        
        // Control:
        // hash_type (1).
        let controlData = hashType.data
        
        // Transaction data:
        // nVersion (4): the nVersion of the transaction.
        var txData = version.data
        // nLockTime (4): the nLockTime of the transaction.
        txData.append(locktime.data)
        
        //If the hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
        if !hashType.isAnyCanPay {
            // sha_prevouts (32): the SHA256 of the serialization of all input outpoints.
            let shaPrevouts: Data
            if let cached = cache.shaPrevouts {
                shaPrevouts = cached
            } else {
                let prevouts = inputs.reduce(Data()) { $0 + $1.outpoint.data }
                shaPrevouts = sha256(prevouts)
                cache.shaPrevouts = shaPrevouts
            }
            cache.shaPrevoutsUsed = true
            txData.append(shaPrevouts)

            // sha_amounts (32): the SHA256 of the serialization of all spent output amounts.
            let shaAmounts: Data
            if let cached = cache.shaAmounts {
                shaAmounts = cached
            } else {
                let amounts = prevOuts.reduce(Data()) { $0 + $1.valueData }
                shaAmounts = sha256(amounts)
                cache.shaAmounts = shaAmounts
            }
            cache.shaAmountsUsed = true
            txData.append(shaAmounts)
            
            // sha_scriptpubkeys (32): the SHA256 of all spent outputs' scriptPubKeys, serialized as script inside CTxOut.
            let shaScriptPubKeys: Data
            if let cached = cache.shaScriptPubKeys {
                shaScriptPubKeys = cached
            } else {
                let scriptPubKeys = prevOuts.reduce(Data()) { $0 + $1.script.prefixedData }
                shaScriptPubKeys = sha256(scriptPubKeys)
                cache.shaScriptPubKeys = shaScriptPubKeys
            }
            cache.shaScriptPubKeysUsed = true
            txData.append(shaScriptPubKeys)

            // sha_sequences (32): the SHA256 of the serialization of all input nSequence.
            let shaSequences: Data
            if let cached = cache.shaSequences {
                shaSequences = cached
            } else {
                let sequences = inputs.reduce(Data()) { $0 + $1.sequence.data }
                shaSequences = sha256(sequences)
                cache.shaSequences = shaSequences
            }
            cache.shaSequencesUsed = true
            txData.append(shaSequences)
        } else {
            cache.shaPrevoutsUsed = false
            cache.shaAmountsUsed = false
            cache.shaScriptPubKeysUsed = false
            cache.shaSequencesUsed = false
        }
        
        // If hash_type & 3 does not equal SIGHASH_NONE or SIGHASH_SINGLE:
        if !hashType.isNone && !hashType.isSingle {
        // sha_outputs (32): the SHA256 of the serialization of all outputs in CTxOut format.
        let shaOuts: Data
            if let cached = cache.shaOuts {
                shaOuts = cached
            } else {
                let outsData = outputs.reduce(Data()) { $0 + $1.data }
                shaOuts = sha256(outsData)
                cache.shaOuts = shaOuts
            }
            cache.shaOutsUsed = true
            txData.append(shaOuts)
        } else {
            cache.shaOutsUsed = false
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise
        var inputData = Data()
        let spendType = (extFlag * 2) + (annex == .none ? 0 : 1)
        inputData.append(spendType)
        
        // If hash_type & 0x80 equals SIGHASH_ANYONECANPAY:
        if hashType.isAnyCanPay {
            // outpoint (36): the COutPoint of this input (32-byte hash + 4-byte little-endian).
            let outpoint = inputs[inIdx].outpoint.data
            inputData.append(outpoint)
            // amount (8): value of the previous output spent by this input.
            let amount = prevOuts[inIdx].valueData
            inputData.append(amount)
            // scriptPubKey (35): scriptPubKey of the previous output spent by this input, serialized as script inside CTxOut. Its size is always 35 bytes.
            let scriptPubKey = prevOuts[inIdx].script.prefixedData
            inputData.append(scriptPubKey)
            // nSequence (4): nSequence of this input.
            let sequence = inputs[inIdx].sequence.data
            inputData.append(sequence)
        } else { // If hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
            // input_index (4): index of this input in the transaction input vector. Index of the first input is 0.
            let inputIndexData = withUnsafeBytes(of: UInt32(inIdx)) { Data($0) }
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
        if hashType.isSingle {
            //sha_single_output (32): the SHA256 of the corresponding output in CTxOut format.
            let shaSingleOutput = sha256(outputs[inIdx].data)
            outputData.append(shaSingleOutput)
        }
        
        let sigMsg = epochData + controlData + txData + inputData + outputData
        return sigMsg
    }
}
