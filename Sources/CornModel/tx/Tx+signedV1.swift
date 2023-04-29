import Foundation

public extension Tx {
    
    mutating func signedV1(privKey: Data, pubKey: Data, hashType: HashType?, inIdx: Int, prevOuts: [Tx.Out]) -> Tx {
        
        let sigHash = sigHashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, extFlag: 0, annex: .none)
        let aux = getRandBytes(32)
        
        let hashTypeSuffix: Data
        if let hashType {
            hashTypeSuffix = hashType.data
        } else {
            hashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sigHash, privKey: privKey, merkleRoot: .none, aux: aux) + hashTypeSuffix
        
        // TODO: this is only for keyPath spending
        var newIns = ins
        newIns[inIdx].witness = [sig]
        return .init(version: version, ins: newIns, outs: outs, lockTime: lockTime)
    }

    mutating func sigHashV1(_ type: HashType?, inIdx: Int, prevOuts: [Tx.Out], extFlag: UInt8, annex: Data?) -> Data {
        let sigMsg = sigMsgV1(hashType: type, inIdx: inIdx, prevOuts: prevOuts, extFlag: extFlag, annex: annex)
        return taggedHash(tag: "TapSighash", payload: sigMsg)
    }
    
    /// SegWit v1 (Schnorr / TapRoot) signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message .
    /// https://github.com/bitcoin/bitcoin/blob/58da1619be7ac13e686cb8bbfc2ab0f836eb3fa5/src/script/interpreter.cpp#L1477
    /// https://bitcoin.stackexchange.com/questions/115328/how-do-you-calculate-a-taproot-sighash
    mutating func sigMsgV1(hashType: HashType?, inIdx: Int, prevOuts: [Tx.Out], extFlag: UInt8, annex: Data?) -> Data {
        
        precondition(prevOuts.count == ins.count, "The corresponding (aligned) UTXO for each transaction input is required.")
        precondition(!hashType.isSingle || inIdx < outs.count, "For single hash type, the selected input needs to have a matching output.")

        // Set up precomputation cache
        var cache = sigMsgV1Cache ?? .init()
        
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
            if let cached = cache.shaPrevouts {
                shaPrevouts = cached
            } else {
                let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
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
                let scriptPubKeys = prevOuts.reduce(Data()) { $0 + $1.scriptPubKey.data.varLenData }
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
                let sequences = ins.reduce(Data()) { $0 + $1.sequenceData }
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
                let outsData = outs.reduce(Data()) { $0 + $1.data }
                shaOuts = sha256(outsData)
                cache.shaOuts = shaOuts
            }
            cache.shaOutsUsed = true
            txData.append(shaOuts)
        } else {
            cache.shaOutsUsed = false
        }
        
        // Data about this input:
        // spend_type (1): equal to (ext_flag * 2) + annex_present, where annex_present is 0 if no annex is present, or 1 otherwise (the original witness stack has two or more witness elements, and the first byte of the last element is 0x50)
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
        sigMsgV1Cache = cache
        return sigMsg
    }
}
