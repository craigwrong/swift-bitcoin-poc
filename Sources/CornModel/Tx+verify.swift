public extension Tx {
    func verify(prevOuts: [Tx.Out]) -> Bool {
        ins.enumerated().reduce(true) {
            let (i, input) = $1
            return $0 && input.verify(prevOuts: prevOuts, index: i)
        }
    }
}

public extension Tx.In {
    func verify(prevOuts: [Tx.Out], index: Int) -> Bool {
        let prevOut = prevOuts
        let scriptOps: [Script.Op]
        switch scriptSig.scriptType {
        case .pubKey, .pubKeyHash, .multiSig, .nonStandard:
            scriptOps = scriptSig.ops + prevOuts[index].scriptPubKey.ops
        case .scriptHash:
            guard let lastOp = scriptSig.ops.last else {
                fatalError()
            }
            scriptOps = [lastOp] + prevOuts[index].scriptPubKey.ops
        case .nullData:
            return false
        case .witnessV0KeyHash:
            fatalError("To be implemented…")
        case .witnessV0ScriptHash:
            fatalError("To be implemented…")
        case .witnessV1TapRoot:
            fatalError("To be implemented…")
        case .witnessUnknown:
            return true
        }
        let fullScript = Script(ops: scriptOps)
        if scriptSig.scriptType == .scriptHash {
            guard let lastOp = scriptSig.ops.last, case let .pushBytes(redeemScriptData) = lastOp else {
                fatalError()
            }
            let redeemScript = Script(redeemScriptData, includeLength: false)
            let fullRedeemScript = Script(ops: scriptSig.ops.dropLast() + redeemScript.ops)
            //fullRedeemScript.run()
            fatalError("To be implemented…")
        } else {
            
        }
        return true
    }
}
