import Foundation

extension Transaction {

    /// Populates unlocking script / witness with signatures.
    public mutating func sign(privKeys: [Data], pubKeys: [Data]? = .none, redeemScript: ParsedScript? = .none, redeemScriptV0: ParsedScript? = .none, scriptTree: ScriptTree? = .none, leafIdx: Int? = .none, taprootAnnex: Data? = .none, sighashType: SighashType? = Optional.none, inputIndex: Int, prevOuts: [Transaction.Output]) {

        if let redeemScript { precondition(redeemScript.version == .legacy) }
        if let redeemScriptV0 { precondition(redeemScriptV0.version == .witnessV0) }


        let prevOut = prevOuts.count == 1 ? prevOuts[0] : prevOuts[inputIndex]
        switch(prevOut.script.outputType) {
        case .pubKey:
            guard let sighashType else { preconditionFailure() }
            signP2PK(privKey: privKeys[0], sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
        case .pubKeyHash:
            guard let sighashType else { preconditionFailure() }
            guard let pubKeys else { preconditionFailure() }
            signP2PKH(privKey: privKeys[0], pubKey: pubKeys[0], sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
        case .multiSig:
            guard let sighashType else { preconditionFailure() }
            signMultiSig(privKeys: privKeys, sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
        case .scriptHash:
            guard let sighashType else { preconditionFailure() }
            guard let redeemScript else { preconditionFailure() }
            if redeemScript.outputType == .witnessV0KeyHash {
                guard let pubKeys else { preconditionFailure() }
                inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(redeemScript.data)]).data)
                signP2WKH(privKey: privKeys[0], pubKey: pubKeys[0], sighashType: sighashType, inputIndex: inputIndex, prevOut: Transaction.Output(value: prevOuts[inputIndex].value, script: redeemScript))
            } else if redeemScript.outputType == .witnessV0ScriptHash {
                guard let redeemScriptV0 else { preconditionFailure() }
                inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(redeemScript.data)]).data)
                signP2WSH(privKeys: privKeys, redeemScript: redeemScriptV0, sighashType: sighashType, inputIndex: inputIndex, prevOut: Transaction.Output(value: prevOuts[inputIndex].value, script: redeemScript))
            } else {
                signP2SH(privKeys: privKeys, redeemScript: redeemScript, sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
            }
        case .witnessV0KeyHash:
            guard let sighashType else { preconditionFailure() }
            guard let pubKeys else { preconditionFailure() }
            signP2WKH(privKey: privKeys[0], pubKey: pubKeys[0], sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
        case .witnessV0ScriptHash:
            guard let sighashType else { preconditionFailure() }
            guard let redeemScriptV0 else { preconditionFailure() }
            signP2WSH(privKeys: privKeys, redeemScript: redeemScriptV0, sighashType: sighashType, inputIndex: inputIndex, prevOut: prevOut)
        case .witnessV1TapRoot:
            if scriptTree != .none {
                precondition(leafIdx != .none)
            }
            signP2TR(privKey: privKeys[0], scriptTree: scriptTree, leafIdx: leafIdx, annex: taprootAnnex, sighashType: sighashType, inputIndex: inputIndex, prevOuts: prevOuts)
        default:
            fatalError()
        }
    }

    mutating func signP2PK(privKey: Data, sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        let sighash = signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: prevOut.script.data)
        let sig = signECDSA(msg: sighash, privKey: privKey) + sighashType.data
        inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(sig)]).data)
    }

    mutating func signP2PKH(privKey: Data, pubKey: Data, sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        let sighash = signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: prevOut.script.data)
        let sig = signECDSA(msg: sighash, privKey: privKey /*, grind: false)*/) + sighashType.data
        inputs[inputIndex].script = SerializedScript(ParsedScript([.pushBytes(sig), .pushBytes(pubKey)]).data)
    }

    mutating func signMultiSig(privKeys: [Data], sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        let sighash = signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: prevOut.script.data)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + sighashType.data }
        let scriptSigOps = sigs.reversed().map { ScriptOperation.pushBytes($0) }

        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = [ScriptOperation.zero]
        inputs[inputIndex].script = SerializedScript(ParsedScript(nullDummy + scriptSigOps).data)
    }
    
    mutating func signP2SH(privKeys: [Data], redeemScript: ParsedScript, sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        precondition(redeemScript.version == .legacy)
        
        let sighash = signatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: redeemScript.data)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + sighashType.data }
        let scriptSigOps = sigs.reversed().map { ScriptOperation.pushBytes($0) }
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.operations.last == .checkMultiSig || redeemScript.operations.last == .checkMultiSig ? [ScriptOperation.zero] : []
        inputs[inputIndex].script = SerializedScript(ParsedScript(nullDummy + scriptSigOps + [.pushBytes(redeemScript.data)]).data)
    }
    
    mutating func signP2WKH(privKey: Data, pubKey: Data, sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        let scriptCode = ParsedScript.makeP2WPKH(hash160(pubKey)).data
        let sighash = segwitSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: scriptCode)
        let sig = signECDSA(msg: sighash, privKey: privKey) + sighashType.data
        inputs[inputIndex].witness = .init([sig, pubKey])
    }

    mutating func signP2WSH(privKeys: [Data], redeemScript: ParsedScript, sighashType: SighashType, inputIndex: Int, prevOut: Transaction.Output) {
        precondition(redeemScript.version == .witnessV0)

        // TODO: Request and operation index an remove code separators from redeem script up to that index.
        let scriptCode = redeemScript.data

        let sighash = segwitSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutput: prevOut, scriptCode: scriptCode)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + sighashType.data }.reversed()
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.operations.last == .checkMultiSig || redeemScript.operations.last == .checkMultiSig ? [Data()] : []
        inputs[inputIndex].witness = .init(nullDummy + sigs + [redeemScript.data])
    }

    mutating func signP2TR(privKey: Data, scriptTree: ScriptTree?, leafIdx: Int?, codesepPos: UInt32 = 0xffffffff, annex: Data?, sighashType: SighashType?, inputIndex: Int, prevOuts: [Transaction.Output]) {
    
        precondition(scriptTree == .none || (scriptTree != .none && leafIdx != .none))
        
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
        
        if let leafIdx, let treeInfo, let merkleRoot {
            let (leaf, _) = treeInfo[leafIdx]
            guard case let .leaf(_, tapscript) = leaf else {
                fatalError()
            }
            let internalKey = getInternalKey(privKey: privKey)
            let outputKey = getOutputKey(privKey: privKey, merkleRoot: merkleRoot)

            let controlBlock = computeControlBlock(internalPubKey: internalKey, leafInfo: treeInfo[leafIdx], merkleRoot: merkleRoot)
            
            witnessElements.append(outputKey)
            witnessElements.append(tapscript)
            witnessElements.append(controlBlock)
        }
        
        if let annex {
            witnessElements.append(annex)
        }
        
        let tapscriptExt: TapscriptExtension?
        if let treeInfo, let leafIdx {
            let (leaf, _) = treeInfo[leafIdx]
            // Only 1 signature supported for this method so codesepPos and tapscriptExt does not have to vary
            let tapLeafHash = leaf.leafHash
            tapscriptExt = .init(tapLeafHash: tapLeafHash, keyVersion: 0, codesepPos: codesepPos)
        } else {
            tapscriptExt = .none
        }
        
        // Again we are only adding a single signature. Note that the script might be required to consume multiple signatures with different code separator positions even.
        let sighash = taprootSignatureHash(sighashType: sighashType, inputIndex: inputIndex, previousOutputs: prevOuts, tapscriptExtension: tapscriptExt)
        let aux = getRandBytes(32)
        
        let sighashTypeSuffix: Data
        if let sighashType {
            sighashTypeSuffix = sighashType.data
        } else {
            sighashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sighash, privKey: privKey, merkleRoot: merkleRoot, aux: aux) + sighashTypeSuffix

        witnessElements[0] = sig
        inputs[inputIndex].witness = .init(witnessElements)
    }
}
