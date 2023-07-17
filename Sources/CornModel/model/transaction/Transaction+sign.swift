import Foundation

extension Transaction {

    /// Populates unlocking script / witness with signatures.
    public mutating func sign(secretKeys: [Data], publicKeys: [Data]? = .none, redeemScript: ParsedScript? = .none, redeemScriptV0: ParsedScript? = .none, scriptTree: ScriptTree? = .none, leafIndex: Int? = .none, taprootAnnex: Data? = .none, sighashType: SighashType? = Optional.none, inputIndex: Int, previousOutputs: [Transaction.Output]) {

        if let redeemScript { precondition(redeemScript.version == .legacy) }
        if let redeemScriptV0 { precondition(redeemScriptV0.version == .witnessV0) }


        let previousOutput = previousOutputs.count == 1 ? previousOutputs[0] : previousOutputs[inputIndex]
        switch(previousOutput.script.outputType) {
        case .publicKey:
            guard let sighashType else { preconditionFailure() }
            signP2PK(secretKey: secretKeys[0], sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
        case .publicKeyHash:
            guard let sighashType else { preconditionFailure() }
            guard let publicKeys else { preconditionFailure() }
            signP2PKH(secretKey: secretKeys[0], publicKey: publicKeys[0], sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
        case .multiSig:
            guard let sighashType else { preconditionFailure() }
            signMultiSig(secretKeys: secretKeys, sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
        case .scriptHash:
            guard let sighashType else { preconditionFailure() }
            guard let redeemScript else { preconditionFailure() }
            if redeemScript.outputType == .witnessV0KeyHash {
                guard let publicKeys else { preconditionFailure() }
                inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(redeemScript.data)]).data)
                signP2WKH(secretKey: secretKeys[0], publicKey: publicKeys[0], sighashType: sighashType, inputIndex: inputIndex, previousOutput: Transaction.Output(value: previousOutputs[inputIndex].value, script: redeemScript))
            } else if redeemScript.outputType == .witnessV0ScriptHash {
                guard let redeemScriptV0 else { preconditionFailure() }
                inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(redeemScript.data)]).data)
                signP2WSH(secretKeys: secretKeys, redeemScript: redeemScriptV0, sighashType: sighashType, inputIndex: inputIndex, previousOutput: Transaction.Output(value: previousOutputs[inputIndex].value, script: redeemScript))
            } else {
                signP2SH(secretKeys: secretKeys, redeemScript: redeemScript, sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
            }
        case .witnessV0KeyHash:
            guard let sighashType else { preconditionFailure() }
            guard let publicKeys else { preconditionFailure() }
            signP2WKH(secretKey: secretKeys[0], publicKey: publicKeys[0], sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
        case .witnessV0ScriptHash:
            guard let sighashType else { preconditionFailure() }
            guard let redeemScriptV0 else { preconditionFailure() }
            signP2WSH(secretKeys: secretKeys, redeemScript: redeemScriptV0, sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput)
        case .witnessV1TapRoot:
            if leafIndex != .none {
                precondition(scriptTree != .none)
            }
            signP2TR(secretKey: secretKeys[0], scriptTree: scriptTree, leafIndex: leafIndex, annex: taprootAnnex, sighashType: sighashType, inputIndex: inputIndex, previousOutputs: previousOutputs)
        default:
            fatalError()
        }
    }

    func createSignature(inputIndex: Int, secretKey: Data, sighashType: SighashType, previousOutput: Transaction.Output, scriptCode: Data) -> Data {
        var sighashCache = Data?.none
        return createSignature(inputIndex: inputIndex, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode, sighashCache: &sighashCache)
    }

    func createSignature(inputIndex: Int, secretKey: Data, sighashType: SighashType, previousOutput: Transaction.Output, scriptCode: Data, sighashCache: inout Data?) -> Data {
        let outputType = previousOutput.script.outputType
        precondition(
            outputType == .nonStandard ||
            outputType == .publicKey ||
            outputType == .publicKeyHash ||
            outputType == .multiSig ||
            outputType == .scriptHash
        )
        let sighash = if let sighashCache {
            sighashCache
        } else {
            signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput, scriptCode: scriptCode)
        }
        if sighashCache == .none {
            sighashCache = sighash
        }
        return signECDSA(message: sighash, secretKey: secretKey) + sighashType.data
    }
    
    func createSegwitSignature(inputIndex: Int, secretKey: Data, sighashType: SighashType, previousOutput: Transaction.Output, scriptCode: Data) -> Data {
        var sighashCache = Data?.none
        return createSegwitSignature(inputIndex: inputIndex, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode, sighashCache: &sighashCache)
    }
    
    func createSegwitSignature(inputIndex: Int, secretKey: Data, sighashType: SighashType, previousOutput: Transaction.Output, scriptCode: Data, sighashCache: inout Data?) -> Data {
        let outputType = previousOutput.script.outputType
        precondition(
            outputType == .witnessV0KeyHash ||
            outputType == .witnessV0ScriptHash
        )
        let sighash = if let sighashCache {
            sighashCache
        } else {
            segwitSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: previousOutput, scriptCode: scriptCode)
        }
        if sighashCache == .none {
            sighashCache = sighash
        }
        return signECDSA(message: sighash, secretKey: secretKey) + sighashType.data
    }
    
    mutating func signP2PK(secretKey: Data, sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        let scriptCode = previousOutput.script.data
        inputs[inputIndex].script = SerializedScript(
            ParsedScript([
                .pushBytes(
                    createSignature(inputIndex: inputIndex, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode)
                )
            ]).data
        )
    }

    mutating func signP2PKH(secretKey: Data, publicKey: Data, sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        let scriptCode = previousOutput.script.data
        inputs[inputIndex].script = SerializedScript(
            ParsedScript([
                .pushBytes(
                    createSignature(inputIndex: inputIndex, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode)
                ),
                .pushBytes(publicKey)
            ]).data
        )
    }

    mutating func signMultiSig(secretKeys: [Data], sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        let scriptCode = previousOutput.script.data
        var sighashCache = Data?.none
        let scriptSigOps = secretKeys.map {
            createSignature(inputIndex: inputIndex, secretKey: $0, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode, sighashCache: &sighashCache)
        }.reversed().map {
            ScriptOperation.pushBytes($0)
        }

        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = [ScriptOperation.zero]
        inputs[inputIndex].script = SerializedScript(ParsedScript(nullDummy + scriptSigOps).data)
    }
    
    mutating func signP2SH(secretKeys: [Data], redeemScript: ParsedScript, sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        let scriptCode = redeemScript.data
        var sighashCache = Data?.none
        let scriptSigOps = secretKeys.map {
            createSignature(inputIndex: inputIndex, secretKey: $0, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode, sighashCache: &sighashCache)
        }.reversed().map {
            ScriptOperation.pushBytes($0)
        }
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.operations.last == .checkMultiSig || redeemScript.operations.last == .checkMultiSig ? [ScriptOperation.zero] : []
        inputs[inputIndex].script = ParsedScript(
            nullDummy + scriptSigOps + [.pushBytes(redeemScript.data)]
        ).serialized
    }
    
    mutating func signP2WKH(secretKey: Data, publicKey: Data, sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        let scriptCode = ParsedScript.makeP2WPKH(hash160(publicKey)).data
        inputs[inputIndex].witness = .init([
            createSegwitSignature(inputIndex: inputIndex, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode),
            publicKey
        ])
    }

    mutating func signP2WSH(secretKeys: [Data], redeemScript: ParsedScript, sighashType: SighashType, inputIndex: Int, previousOutput: Transaction.Output) {
        precondition(redeemScript.version == .witnessV0)

        // TODO: Request and operation index an remove code separators from redeem script up to that index.
        let scriptCode = redeemScript.data

        var sighashCache = Data?.none
        let sigs = secretKeys.map { createSegwitSignature(inputIndex: inputIndex, secretKey: $0, sighashType: sighashType, previousOutput: previousOutput, scriptCode: scriptCode, sighashCache: &sighashCache) }.reversed()
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.operations.last == .checkMultiSig || redeemScript.operations.last == .checkMultiSig ? [ScriptNumber.zero.data] : []
        inputs[inputIndex].witness = .init(nullDummy + sigs + [redeemScript.data])
    }

    mutating func signP2TR(secretKey: Data, scriptTree: ScriptTree?, leafIndex: Int?, codesepPos: UInt32 = 0xffffffff, annex: Data?, sighashType: SighashType?, inputIndex: Int, previousOutputs: [Transaction.Output]) {
    
        precondition(leafIndex == .none || (leafIndex != .none && scriptTree != .none))
        
        // WARN: We support adding only a single signature for now. Therefore we only take one codesepPos (OP_CODESEPARATOR position)
        var witnessElements = [Data()] // Placeholder for the signature
        
        let treeInfo: [(ScriptTree, Data)]?
        let merkleRoot: Data?
        if let scriptTree {
            (treeInfo, merkleRoot) = scriptTree.calcMerkleRoot()
        } else {
            treeInfo = .none
            merkleRoot = .none
        }
        
        if let leafIndex, let treeInfo, let merkleRoot {
            let (leaf, _) = treeInfo[leafIndex]
            guard case let .leaf(_, tapscript) = leaf else {
                fatalError()
            }
            let internalKey = getInternalKey(secretKey: secretKey)

            let controlBlock = computeControlBlock(internalPublicKey: internalKey, leafInfo: treeInfo[leafIndex], merkleRoot: merkleRoot)
            
            witnessElements.append(internalKey)
            witnessElements.append(tapscript)
            witnessElements.append(controlBlock)
        }
        
        if let annex {
            witnessElements.append(annex)
        }
        
        let tapscriptExt: TapscriptExtension?
        if let leafIndex, let treeInfo {
            let (leaf, _) = treeInfo[leafIndex]
            // Only 1 signature supported for this method so codesepPos and tapscriptExt does not have to vary
            let tapLeafHash = leaf.leafHash
            tapscriptExt = .init(tapLeafHash: tapLeafHash, keyVersion: 0, codesepPos: codesepPos)
        } else {
            tapscriptExt = .none
        }
        
        // Again we are only adding a single signature. Note that the script might be required to consume multiple signatures with different code separator positions even.
        let sighash = taprootSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutputs: previousOutputs, tapscriptExtension: tapscriptExt)
        let aux = getRandBytes(32)
        
        let sighashTypeSuffix: Data
        if let sighashType {
            sighashTypeSuffix = sighashType.data
        } else {
            sighashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sighash, secretKey: secretKey, merkleRoot: merkleRoot, skipTweak: leafIndex != .none, aux: aux) + sighashTypeSuffix

        witnessElements[0] = sig
        inputs[inputIndex].witness = .init(witnessElements)
    }
}
