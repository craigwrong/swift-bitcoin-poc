import Foundation

public extension Tx {
    
    func sign(privKey: Data, pubKey: Data, redeemScript: Script? = .none, inIdx: Int, prevOuts: [Tx.Out], sigHashType: SigHashType) -> Tx {
        switch(prevOuts[inIdx].scriptPubKey.scriptType) {
        case .nonStandard:
            fatalError("Signing of non-standard scripts is not implemented.")
        case .pubKey, .pubKeyHash:
            return signed(privKey: privKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .scriptHash:
            guard let redeemScript else {
                fatalError("Missing required redeem script.")
            }
            if redeemScript.scriptType == .witnessV0KeyHash {
                // TODO: Pass redeem script on to add to input's script sig
                var withScriptSig = self
                withScriptSig.ins[inIdx].scriptSig = .init([.pushBytes(redeemScript.data(includeLength: false))])
                return withScriptSig.signedV0(privKey: privKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
            }
            // TODO: Handle P2SH-P2WSH
            return signed(privKey: privKey, pubKey: pubKey, redeemScript: redeemScript, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .multiSig:
            fatalError("Signing of legacy multisig transactions is not yet implemented.")
        case .nullData:
            fatalError("Null data script transactions cannot be signed nor spent.")
        case .witnessV0KeyHash:
            return signedV0(privKey: privKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .witnessV0ScriptHash:
            fatalError("Signing of P2WSH transactions is not yet implemented.")
        case .witnessV1TapRoot:
            return signedV1(privKey: privKey, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts, sigHashType: sigHashType)
        case .witnessUnknown:
            fatalError("Signing of transactions with witness script version higher than 1 is not yet implemented.")
        }
    }
}
