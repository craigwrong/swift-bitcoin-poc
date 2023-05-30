import Foundation

public extension Tx {

    /// Populates unlocking script / witness with signatures and provided redeem script.
    mutating func signInput(privKey: Data, pubKey: Data? = .none, redeemScript: ScriptLegacy, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
        let pubKey = pubKey ?? getPubKey(privKey: privKey)
        switch(prevOuts[inIdx].scriptPubKey.scriptType) {
        case .scriptHash:
            if redeemScript.scriptType == .witnessV0KeyHash {
                // TODO: Pass redeem script on to add to input's script sig
                ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data)])
                signV0(privKey: privKey, pubKey: pubKey, hashType: hashType, inIdx: inIdx, prevOut: Tx.Out(value: prevOuts[inIdx].value, scriptPubKeyData: redeemScript.data))
                return
            }
            // TODO: Handle P2SH-P2WSH
            sign(privKey: privKey, pubKey: pubKey, redeemScript: redeemScript, hashType: hashType, inIdx: inIdx, prevOut: prevOuts[inIdx])
        default:
            fatalError()
        }
    }

    /// Populates unlocking script / witness with signatures.
    mutating func signInput(privKey: Data, pubKey: Data? = .none, hashType: HashType, inIdx: Int, prevOuts: [Tx.Out]) {
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
            signV1(privKey: privKey, pubKey: pubKey, hashType: hashType, inIdxs: [inIdx], prevOuts: prevOuts)
        default:
            fatalError()
        }
    }
}
