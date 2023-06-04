import Foundation

extension Tx {

    /// Populates unlocking script / witness with signatures.
    public mutating func signInput(privKeys: [Data], pubKeys: [Data]? = .none, redeemScript: ScriptLegacy? = .none, redeemScriptV0: ScriptV0? = .none, tapscript: ScriptV1? = .none, taprootAnnex: Data? = .none, hashType: HashType? = Optional.none, inIdx: Int, prevOuts: [Tx.Out]) {
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
            signP2TR(privKey: privKeys[0], tapscript: tapscript, annex: taprootAnnex, hashType: hashType, inIdx: inIdx, prevOuts: prevOuts)
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
        let scriptSigOps = sigs.reversed().map { ScriptLegacy.Op.pushBytes($0) }

        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = [ScriptLegacy.Op.zero]
        ins[inIdx].scriptSig = .init(nullDummy + scriptSigOps)
    }
    
    mutating func signP2SH(privKeys: [Data], redeemScript: ScriptLegacy, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: redeemScript, opIdx: 0)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + hashType.data }
        let scriptSigOps = sigs.reversed().map { ScriptLegacy.Op.pushBytes($0) }
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.ops.last == .checkMultiSig || redeemScript.ops.last == .checkMultiSig ? [ScriptLegacy.Op.zero] : []
        ins[inIdx].scriptSig = .init(nullDummy + scriptSigOps + [.pushBytes(redeemScript.data)])
    }
    
    mutating func signP2WKH(privKey: Data, pubKey: Data, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let scriptCode = ScriptV0.keyHashScript(hash160(pubKey))
        let sighash = sighashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: 0)
        let sig = signECDSA(msg: sighash, privKey: privKey) + hashType.data
        ins[inIdx].witness = [sig, pubKey]
    }

    mutating func signP2WSH(privKeys: [Data], redeemScript: ScriptV0, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sighash = sighashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: redeemScript, opIdx: 0)
        let sigs = privKeys.map { signECDSA(msg: sighash, privKey: $0) + hashType.data }.reversed()
        
        // https://github.com/bitcoin/bips/blob/master/bip-0147.mediawiki
        let nullDummy = redeemScript.ops.last == .checkMultiSig || redeemScript.ops.last == .checkMultiSig ? [Data()] : []
        ins[inIdx].witness = nullDummy + sigs + [redeemScript.data]
    }

    mutating func signP2TR(privKey: Data, tapscript: ScriptV1?, codesepPos: UInt32 = 0xffffffff, annex: Data?, hashType: HashType?, inIdx: Int, prevOuts: [Tx.Out]) {
        var cache = SigMsgV1Cache?.some(.init())
        
        // WARN: We support adding only a single signature for now. Therefore we only take one codesepPos (OP_CODESEPARATOR position)
        ins[inIdx].witness = [Data()] // Placeholder for the signature
        
        if let annex {
            ins[inIdx].witness?.append(annex)
        }
        
        let tapscriptExt: TapscriptExt?
        if let tapscript {
            // Only 1 signature supported for this method so codesepPos and tapscriptExt does not have to vary
            tapscriptExt = .init(tapLeafHash: tapscript.tapLeafHash, keyVersion: tapscript.keyVersion, codesepPos: codesepPos)
        } else {
            tapscriptExt = .none
        }
        
        // Again we are only adding a single signature. Note that the script might be required to consume multiple signatures with different code separator positions even.
        let sighash = sighashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, tapscriptExt: tapscriptExt, cache: &cache)
        let aux = getRandBytes(32)
        
        let hashTypeSuffix: Data
        if let hashType {
            hashTypeSuffix = hashType.data
        } else {
            hashTypeSuffix = Data()
        }
        let sig = signSchnorr(msg: sighash, privKey: privKey, merkleRoot: .none, aux: aux) + hashTypeSuffix

        ins[inIdx].witness?[0] = sig
    }
}
