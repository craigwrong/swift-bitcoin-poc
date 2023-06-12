import Foundation

extension Tx {

    /// Populates unlocking script / witness with signatures.
    public mutating func sign(privKeys: [Data], pubKeys: [Data]? = .none, redeemScript: [Op]? = .none, redeemScriptV0: [Op]? = .none, scriptTree: ScriptTree? = .none, leafIdx: Int? = .none, taprootAnnex: Data? = .none, hashType: HashType? = Optional.none, inIdx: Int, prevOuts: [Tx.Out]) {
        let prevOut = prevOuts.count == 1 ? prevOuts[0] : prevOuts[inIdx]
        switch(prevOut.scriptPubKey.scriptType) {
        case .pubKey:
            guard let hashType else { preconditionFailure() }
            signP2PK(privKey: privKeys[0], hashType: hashType, inIdx: inIdx, prevOut: prevOut)
        case .pubKeyHash:
            guard let hashType else { preconditionFailure() }
            guard let pubKeys else { preconditionFailure() }
            signP2PKH(privKey: privKeys[0], pubKey: pubKeys[0], hashType: hashType, inIdx: inIdx, prevOut: prevOut)
        case .multiSig:
            guard let hashType else { preconditionFailure() }
            signMultiSig(privKeys: privKeys, hashType: hashType, inIdx: inIdx, prevOut: prevOut)
        case .scriptHash:
            guard let hashType else { preconditionFailure() }
            guard let redeemScript else { preconditionFailure() }
            if redeemScript.scriptType == .witnessV0KeyHash {
                guard let pubKeys else { preconditionFailure() }
                ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data)])
                signP2WKH(privKey: privKeys[0], pubKey: pubKeys[0], hashType: hashType, inIdx: inIdx, prevOut: Tx.Out(value: prevOuts[inIdx].value, scriptPubKey: redeemScript))
            } else if redeemScript.scriptType == .witnessV0ScriptHash {
                guard let redeemScriptV0 else { preconditionFailure() }
                ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data)])
                signP2WSH(privKeys: privKeys, redeemScript: redeemScriptV0, hashType: hashType, inIdx: inIdx, prevOut: Tx.Out(value: prevOuts[inIdx].value, scriptPubKey: redeemScript))
            } else {
                signP2SH(privKeys: privKeys, redeemScript: redeemScript, hashType: hashType, inIdx: inIdx, prevOut: prevOut)
            }
        case .witnessV0KeyHash:
            guard let hashType else { preconditionFailure() }
            guard let pubKeys else { preconditionFailure() }
            signP2WKH(privKey: privKeys[0], pubKey: pubKeys[0], hashType: hashType, inIdx: inIdx, prevOut: prevOut)
        case .witnessV0ScriptHash:
            guard let hashType else { preconditionFailure() }
            guard let redeemScriptV0 else { preconditionFailure() }
            signP2WSH(privKeys: privKeys, redeemScript: redeemScriptV0, hashType: hashType, inIdx: inIdx, prevOut: prevOut)
        case .witnessV1TapRoot:
            if scriptTree != .none {
                precondition(leafIdx != .none)
            }
            signP2TR(privKey: privKeys[0], scriptTree: scriptTree, leafIdx: leafIdx, annex: taprootAnnex, hashType: hashType, inIdx: inIdx, prevOuts: prevOuts)
        default:
            fatalError()
        }
    }

    mutating func signP2PK(privKey: Data, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: prevOut.scriptPubKey, opIdx: 0)
        let sig = signECDSA(msg: sighash, privKey: privKey) + hashType.data
        ins[inIdx].scriptSig = .init([.pushBytes(sig)])
    }

    mutating func signP2PKH(privKey: Data, pubKey: Data, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: prevOut.scriptPubKey, opIdx: 0)
        let sig = signECDSA(msg: sighash, privKey: privKey /*, grind: false)*/) + hashType.data
        ins[inIdx].scriptSig = .init([.pushBytes(sig), .pushBytes(pubKey)])
    }

    mutating func signMultiSig(privKeys: [Data], hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: prevOut.scriptPubKey, opIdx: 0)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + hashType.data }
        let scriptSigOps = sigs.reversed().map { Op.pushBytes($0) }

        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = [Op.zero]
        ins[inIdx].scriptSig = .init(nullDummy + scriptSigOps)
    }
    
    mutating func signP2SH(privKeys: [Data], redeemScript: [Op], hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: redeemScript, opIdx: 0)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + hashType.data }
        let scriptSigOps = sigs.reversed().map { Op.pushBytes($0) }
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.last == .checkMultiSig || redeemScript.last == .checkMultiSig ? [Op.zero] : []
        ins[inIdx].scriptSig = .init(nullDummy + scriptSigOps + [.pushBytes(redeemScript.data)])
    }
    
    mutating func signP2WKH(privKey: Data, pubKey: Data, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let scriptCode = makeP2WPKH(hash160(pubKey))
        let sighash = sighashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: 0)
        let sig = signECDSA(msg: sighash, privKey: privKey) + hashType.data
        ins[inIdx].witness = [sig, pubKey]
    }

    mutating func signP2WSH(privKeys: [Data], redeemScript: [Op], hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: redeemScript, opIdx: 0)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + hashType.data }.reversed()
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.last == .checkMultiSig || redeemScript.last == .checkMultiSig ? [Data()] : []
        ins[inIdx].witness = nullDummy + sigs + [redeemScript.data]
    }

    mutating func signP2TR(privKey: Data, scriptTree: ScriptTree?, leafIdx: Int?, codesepPos: UInt32 = 0xffffffff, annex: Data?, hashType: HashType?, inIdx: Int, prevOuts: [Tx.Out]) {
    
        precondition(scriptTree == .none || (scriptTree != .none && leafIdx != .none))
        
        // WARN: We support adding only a single signature for now. Therefore we only take one codesepPos (OP_CODESEPARATOR position)
        ins[inIdx].witness = [Data()] // Placeholder for the signature
        
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
            
            ins[inIdx].witness?.append(outputKey)
            ins[inIdx].witness?.append(tapscript.data)
            ins[inIdx].witness?.append(controlBlock)
        }
        
        if let annex {
            ins[inIdx].witness?.append(annex)
        }
        
        let tapscriptExt: TapscriptExt?
        if let treeInfo, let leafIdx {
            let (leaf, _) = treeInfo[leafIdx]
            // Only 1 signature supported for this method so codesepPos and tapscriptExt does not have to vary
            let tapLeafHash = leaf.leafHash
            tapscriptExt = .init(tapLeafHash: tapLeafHash, keyVersion: 0, codesepPos: codesepPos)
        } else {
            tapscriptExt = .none
        }
        
        // Again we are only adding a single signature. Note that the script might be required to consume multiple signatures with different code separator positions even.
        let sighash = sighashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, tapscriptExt: tapscriptExt)
        let aux = getRandBytes(32)
        
        let hashTypeSuffix: Data
        if let hashType {
            hashTypeSuffix = hashType.data
        } else {
            hashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sighash, privKey: privKey, merkleRoot: merkleRoot, aux: aux) + hashTypeSuffix

        ins[inIdx].witness?[0] = sig
    }
}
