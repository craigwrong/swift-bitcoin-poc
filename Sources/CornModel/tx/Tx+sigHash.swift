import Foundation

extension Tx {

    // - Legacy

    func sighash(_ type: HashType, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptLegacy, opIdx: Int) -> Data {
        
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let subScript: ScriptLegacy
        if prevOut.scriptPubKey.scriptType == .scriptHash {
            // TODO: This check might be redundant as the given script code should always be the redeem script in p2sh checksig
            if let op = ins[inIdx].scriptSig?.ops.last, case let .pushBytes(redeemScriptRaw) = op, ScriptLegacy(redeemScriptRaw) != scriptCode {
                preconditionFailure()
            }
            subScript = scriptCode
        } else {
            // TODO: Account for code separators. Find the last executed one and remove anything before it. After that, remove all remaining OP_CODESEPARATOR instances from script code
            var scriptCode = scriptCode
            scriptCode.removeSubScripts(before: opIdx)
            scriptCode.removeCodeSeparators()
            subScript = scriptCode
            // TODO: FindAndDelete any signature data in subScript (coming scriptPubKey, not standard to have sigs there anyway).
        }
        let sigMsg = sigMsg(hashType: type, inIdx: inIdx, subScript: subScript)
        return hash256(sigMsg)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func sigMsg(hashType: HashType, inIdx: Int, subScript: ScriptLegacy) -> Data {
        var newIns = [Tx.In]()
        if hashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newIns.append(.init(txID: ins[inIdx].txID, outIdx: ins[inIdx].outIdx, sequence: ins[inIdx].sequence, scriptSig: subScript))
        } else {
            ins.enumerated().forEach { i, input in
                newIns.append(.init(
                    txID: input.txID,
                    outIdx: input.outIdx,
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: i == inIdx || hashType.isAll ? input.sequence : 0,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    scriptSig: i == inIdx ? subScript : .init([])
                ))
            }
        }
        var newOuts: [Tx.Out]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if hashType.isSingle && inIdx >= outs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if hashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOuts = []
            
            outs.enumerated().forEach { i, out in
                guard i <= inIdx else {
                    return
                }
                if i == inIdx {
                    newOuts.append(out)
                } else if i < inIdx {
                    // TODO: Verify that "long -1" means  UInt64(bitPattern: -1) aka UInt64.max
                    newOuts.append(.init(value: UInt64.max, scriptPubKeyData: .init()))
                }
            }
            
        } else if hashType.isNone {
            newOuts = []
        } else {
            newOuts = outs
        }
        let txCopy = Tx(
            version: version,
            lockTime: lockTime,
            ins: newIns,
            outs: newOuts
        )
        return txCopy.data + hashType.data32
    }
    
    // TODO: Remove once newer implementation was tested.
    func sigMsgAlt(hashType: HashType, inIdx: Int, scriptCode subScript: ScriptLegacy) -> Data {
        let input = ins[inIdx]
        var txCopy = self
        txCopy.ins.indices.forEach {
            txCopy.ins[$0].scriptSig = .init([])
            txCopy.ins[$0].witness = .none
        }
        txCopy.ins[inIdx].scriptSig = subScript
        if hashType.isNone {
            txCopy.outs = []
        } else if hashType.isSingle {
            txCopy.outs = []
            outs.enumerated().forEach { (i, out) in
                if i == inIdx {
                    txCopy.outs.append(out)
                } else if i < inIdx {
                    txCopy.outs.append(.init(value: UInt64.max, scriptPubKeyData: .init()))
                }
            }
        }
        if hashType.isNone || hashType.isSingle {
            txCopy.ins.indices.forEach {
                if $0 != inIdx {
                    txCopy.ins[$0].sequence = 0
                }
            }
        }
        if hashType.isAnyCanPay {
            txCopy.ins = [input]
            txCopy.ins[0].scriptSig = subScript
        }
        return txCopy.data + hashType.data32
    }

    // - Witness V0

    func sighashV0(_ type: HashType, inIdx: Int, prevOut: Tx.Out, scriptCode: [Op], opIdx: Int) -> Data {
        // if the witnessScript contains any OP_CODESEPARATOR, the scriptCode is the witnessScript but removing everything up to and including the last executed OP_CODESEPARATOR before the signature checking opcode being executed, serialized as scripts inside CTxOut.
        var scriptCode = scriptCode
        scriptCode.removeSubScripts(before: opIdx)
        let amount = prevOut.value
        return hash256(sigMsgV0(hashType: type, inIdx: inIdx, scriptCode: scriptCode, amount: amount))
    }

    /// SegWit v0 signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#specification .
    func sigMsgV0(hashType: HashType, inIdx: Int, scriptCode: [Op], amount: UInt64) -> Data {
        
        //If the ANYONECANPAY flag is not set, hashPrevouts is the double SHA256 of the serialization of all input outpoints;
        // Otherwise, hashPrevouts is a uint256 of 0x0000......0000.
        var hashPrevouts: Data
        if hashType.isAnyCanPay {
            hashPrevouts = Data(repeating: 0, count: 256)
        } else {
            let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
            hashPrevouts = hash256(prevouts)
        }
        
        // If none of the ANYONECANPAY, SINGLE, NONE sighash type is set, hashSequence is the double SHA256 of the serialization of nSequence of all inputs;
        // Otherwise, hashSequence is a uint256 of 0x0000......0000.
        let hashSequence: Data
        if !hashType.isAnyCanPay && !hashType.isSingle && !hashType.isNone {
            let sequence = ins.reduce(Data()) {
                $0 + withUnsafeBytes(of: $1.sequence) { Data($0) }
            }
            hashSequence = hash256(sequence)
        } else {
            hashSequence = Data(repeating: 0, count: 256)
        }
        
        let outpointData = ins[inIdx].prevoutData
        
        let scriptCodeData = scriptCode.data.varLenData
        
        let amountData = withUnsafeBytes(of: amount) { Data($0) }
        let sequenceData = withUnsafeBytes(of: ins[inIdx].sequence) { Data($0) }
        
        // If the sighash type is neither SINGLE nor NONE, hashOutputs is the double SHA256 of the serialization of all output amount (8-byte little endian) with scriptPubKey (serialized as scripts inside CTxOuts);
        // If sighash type is SINGLE and the input index is smaller than the number of outputs, hashOutputs is the double SHA256 of the output amount with scriptPubKey of the same index as the input;
        // Otherwise, hashOutputs is a uint256 of 0x0000......0000.[7]
        let hashOuts: Data
        if !hashType.isSingle && !hashType.isNone {
            let outsData = outs.reduce(Data()) { $0 + $1.data }
            hashOuts = hash256(outsData)
        } else if hashType.isSingle && inIdx < outs.count {
            hashOuts = hash256(outs[inIdx].data)
        } else {
            hashOuts = Data(repeating: 0, count: 256)
        }
        
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }
        
        let remaindingData = sequenceData + hashOuts + lockTimeData + hashType.data32
        return version.data + hashPrevouts + hashSequence + outpointData + scriptCodeData + amountData + remaindingData
    }

    // - Witness V1

    mutating func sighashV1(_ type: HashType?, inIdx: Int, prevOuts: [Tx.Out], tapscriptExt: TapscriptExt? = .none, cache: inout SigMsgV1Cache?) -> Data {
        var payload = sigMsgV1(hashType: type, extFlag: tapscriptExt == .none ? 0 : 1, inIdx: inIdx, prevOuts: prevOuts, cache: &cache)
        if let tapscriptExt {
            payload += tapscriptExt.data
        }
        return taggedHash(tag: "TapSighash", payload: payload)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    /// https://bitcoin.stackexchange.com/questions/115328/how-do-you-calculate-a-taproot-sighash
    func sigMsgV1(hashType: HashType?, extFlag: UInt8 = 0, inIdx: Int, prevOuts: [Tx.Out], cache: inout SigMsgV1Cache?) -> Data {
        
        precondition(prevOuts.count == ins.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        precondition(!hashType.isSingle || inIdx < outs.count, "For single hash type, the selected input needs to have a matching output.")

        // (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
        let annex = ins[inIdx].taprootAnnex

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
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }
        txData.append(lockTimeData)
        
        //If the hash_type & 0x80 does not equal SIGHASH_ANYONECANPAY:
        if !hashType.isAnyCanPay {
            // sha_prevouts (32): the SHA256 of the serialization of all input outpoints.
            let shaPrevouts: Data
            if let cached = cache?.shaPrevouts {
                shaPrevouts = cached
            } else {
                let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
                shaPrevouts = sha256(prevouts)
                cache?.shaPrevouts = shaPrevouts
            }
            cache?.shaPrevoutsUsed = true
            txData.append(shaPrevouts)

            // sha_amounts (32): the SHA256 of the serialization of all spent output amounts.
            let shaAmounts: Data
            if let cached = cache?.shaAmounts {
                shaAmounts = cached
            } else {
                let amounts = prevOuts.reduce(Data()) { $0 + $1.valueData }
                shaAmounts = sha256(amounts)
                cache?.shaAmounts = shaAmounts
            }
            cache?.shaAmountsUsed = true
            txData.append(shaAmounts)
            
            // sha_scriptpubkeys (32): the SHA256 of all spent outputs' scriptPubKeys, serialized as script inside CTxOut.
            let shaScriptPubKeys: Data
            if let cached = cache?.shaScriptPubKeys {
                shaScriptPubKeys = cached
            } else {
                let scriptPubKeys = prevOuts.reduce(Data()) { $0 + $1.scriptPubKey.data.varLenData }
                shaScriptPubKeys = sha256(scriptPubKeys)
                cache?.shaScriptPubKeys = shaScriptPubKeys
            }
            cache?.shaScriptPubKeysUsed = true
            txData.append(shaScriptPubKeys)

            // sha_sequences (32): the SHA256 of the serialization of all input nSequence.
            let shaSequences: Data
            if let cached = cache?.shaSequences {
                shaSequences = cached
            } else {
                let sequences = ins.reduce(Data()) { $0 + $1.sequenceData }
                shaSequences = sha256(sequences)
                cache?.shaSequences = shaSequences
            }
            cache?.shaSequencesUsed = true
            txData.append(shaSequences)
        } else {
            cache?.shaPrevoutsUsed = false
            cache?.shaAmountsUsed = false
            cache?.shaScriptPubKeysUsed = false
            cache?.shaSequencesUsed = false
        }
        
        // If hash_type & 3 does not equal SIGHASH_NONE or SIGHASH_SINGLE:
        if !hashType.isNone && !hashType.isSingle {
        // sha_outputs (32): the SHA256 of the serialization of all outputs in CTxOut format.
        let shaOuts: Data
            if let cached = cache?.shaOuts {
                shaOuts = cached
            } else {
                let outsData = outs.reduce(Data()) { $0 + $1.data }
                shaOuts = sha256(outsData)
                cache?.shaOuts = shaOuts
            }
            cache?.shaOutsUsed = true
            txData.append(shaOuts)
        } else {
            cache?.shaOutsUsed = false
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise
        var inputData = Data()
        let spendType = (extFlag * 2) + (annex == .none ? 0 : 1)
        inputData.append(spendType)
        
        // If hash_type & 0x80 equals SIGHASH_ANYONECANPAY:
        if hashType.isAnyCanPay {
            // outpoint (36): the COutPoint of this input (32-byte hash + 4-byte little-endian).
            let outpoint = ins[inIdx].prevoutData
            inputData.append(outpoint)
            // amount (8): value of the previous output spent by this input.
            let amount = prevOuts[inIdx].valueData
            inputData.append(amount)
            // scriptPubKey (35): scriptPubKey of the previous output spent by this input, serialized as script inside CTxOut. Its size is always 35 bytes.
            let scriptPubKey = prevOuts[inIdx].scriptPubKey.data.varLenData
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
            let shaSingleOutput = sha256(outs[inIdx].data)
            outputData.append(shaSingleOutput)
        }
        
        let sigMsg = epochData + controlData + txData + inputData + outputData
        return sigMsg
    }
}
