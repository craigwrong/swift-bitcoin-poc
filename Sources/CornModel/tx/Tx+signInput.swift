import Foundation

extension Tx {

    /// Populates unlocking script / witness with signatures.
    public mutating func signInput(privKey: Data, pubKey: Data? = .none, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
        let pubKey = pubKey ?? getPubKey(privKey: privKey)
        switch(prevOuts[inIdx].scriptPubKey.scriptType) {
        case .pubKey, .pubKeyHash:
            sign(privKey: privKey, pubKey: pubKey, hashType: hashType, inIdx: inIdx, prevOut: prevOuts[inIdx])
        case .multiSig:
            // TODO: Receive array of privKey instead and fill scriptSig with corresponding signatures
            fatalError("Signing of legacy multisig transactions is not yet implemented.")
        case .nonStandard:
            // TODO: Do the same as multiSig
            fatalError("Signing of non-standard scripts is not implemented.")
        case .witnessV0KeyHash:
            signV0(privKey: privKey, pubKey: pubKey, hashType: hashType, inIdx: inIdx, prevOut: prevOuts[inIdx])
        case .witnessV1TapRoot:
            signV1(privKey: privKey, hashType: hashType, inIdxs: [inIdx], prevOuts: prevOuts)
        default:
            fatalError()
        }
    }

    public mutating func signInput(privKey: Data, pubKey: Data? = .none, redeemScript: ScriptV0, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
        precondition(prevOuts[inIdx].scriptPubKey.scriptType == .witnessV0ScriptHash)
        let pubKey = pubKey ?? getPubKey(privKey: privKey)
        signV0(privKey: privKey, pubKey: pubKey, redeemScript: redeemScript, hashType: hashType, inIdx: inIdx, prevOut: prevOuts[inIdx])
    }

    /// Populates unlocking script / witness with signatures and provided redeem script.
    public mutating func signInput(privKey: Data, pubKey: Data? = .none, redeemScript: ScriptLegacy, redeemScriptV0: ScriptV0, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
        precondition(prevOuts[inIdx].scriptPubKey.scriptType == .scriptHash && redeemScript.scriptType == .witnessV0ScriptHash)
        let pubKey = pubKey ?? getPubKey(privKey: privKey)
        ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data)])
        signV0(privKey: privKey, pubKey: pubKey, redeemScript: redeemScriptV0, hashType: hashType, inIdx: inIdx, prevOut: Tx.Out(value: prevOuts[inIdx].value, scriptPubKeyData: redeemScript.data))
    }

    /// Populates unlocking script / witness with signatures and provided redeem script.
    public mutating func signInput(privKey: Data, pubKey: Data? = .none, redeemScript: ScriptLegacy, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
        precondition(prevOuts[inIdx].scriptPubKey.scriptType == .scriptHash && redeemScript.scriptType != .witnessV0ScriptHash)
        let pubKey = pubKey ?? getPubKey(privKey: privKey)
        if redeemScript.scriptType == .witnessV0KeyHash {
            // TODO: Pass redeem script on to add to input's script sig
            ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data)])
            signV0(privKey: privKey, pubKey: pubKey, hashType: hashType, inIdx: inIdx, prevOut: Tx.Out(value: prevOuts[inIdx].value, scriptPubKeyData: redeemScript.data))
            return
        }
        sign(privKey: privKey, pubKey: pubKey, redeemScript: redeemScript, hashType: hashType, inIdx: inIdx, prevOut: prevOuts[inIdx])
    }
    
    mutating func sign(privKey: Data, pubKey: Data, redeemScript: ScriptLegacy? = .none, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let sigHash = sigHash(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: redeemScript ?? prevOut.scriptPubKey, opIdx: 0)
        
        let sig = signECDSA(msg: sigHash, privKey: privKey /*, grind: false)*/) + hashType.data
        
        let newScriptSig: ScriptLegacy
        if prevOut.scriptPubKey.scriptType == .pubKey {
            newScriptSig = .init([.pushBytes(sig)])
        } else if prevOut.scriptPubKey.scriptType == .pubKeyHash {
            newScriptSig = .init([
                .pushBytes(sig),
                .pushBytes(pubKey)
            ])
        } else if prevOut.scriptPubKey.scriptType == .scriptHash, let redeemScript {
            newScriptSig = .init([.pushBytes(sig), .pushBytes(redeemScript.data)])
        } else {
            fatalError("Can only sign p2pk, p2pkh and p2sh.")
        }
        ins[inIdx].scriptSig = newScriptSig
    }

    mutating func signV0(privKey: Data, pubKey: Data, redeemScript: ScriptV0? = .none, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        let scriptCode = redeemScript ?? ScriptV0.keyHashScript(hash160(pubKey))
        let sigHash = sigHashV0(hashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: 0)
        let sig = signECDSA(msg: sigHash, privKey: privKey) + hashType.data
        if let redeemScript {
            ins[inIdx].witness = [sig, redeemScript.data]
        } else {
            ins[inIdx].witness = [sig, pubKey]
        }
    }

    mutating func signV1(privKey: Data, hashType: HashType?, inIdxs: [Int], prevOuts: [Tx.Out]) {
        var cache = SigMsgV1Cache?.some(.init())
        for inIdx in inIdxs {
            let sigHash = sigHashV1(hashType, inIdx: inIdx, prevOuts: prevOuts, extFlag: 0, annex: .none, cache: &cache)
            let aux = getRandBytes(32)
            
            let hashTypeSuffix: Data
            if let hashType {
                hashTypeSuffix = hashType.data
            } else {
                hashTypeSuffix = Data()
            }
            let sig = signSchnorr(msg: sigHash, privKey: privKey, merkleRoot: .none, aux: aux) + hashTypeSuffix
            // TODO: this is only for keyPath spending
            ins[inIdx].witness = [sig]
        }
    }
}
