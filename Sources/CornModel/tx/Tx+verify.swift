import Foundation
public extension Tx {
    func verify(prevOuts: [Tx.Out]) -> Bool {
        ins.indices.reduce(true) { result, i in
            result && verify(prevOuts: prevOuts, inIdx: i)
        }
    }
    
    func verify(prevOuts: [Tx.Out], inIdx: Int) -> Bool {
        let input = ins[inIdx]
        let prevOut = prevOuts[inIdx]
        let scriptSig = input.scriptSig
        
        var stack = [Data]()
        let scriptSig2: Script
        switch scriptSig.scriptType {
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown:
            let script = Script(scriptSig.ops + prevOut.scriptPubKey.ops)
            return script.run(stack: &stack, tx: self, prevOuts: prevOuts, inIdx: inIdx)
        case .scriptHash:
            guard let lastOp = scriptSig.ops.last else {
                return false
            }
            let script = Script([lastOp] + prevOuts[inIdx].scriptPubKey.ops)
            guard script.run(stack: &stack, tx: self, prevOuts: prevOuts, inIdx: inIdx) else {
                return false
            }
            guard let lastOp = scriptSig.ops.last, case let .pushBytes(redeemScriptData) = lastOp else {
                fatalError()
            }
            let redeemScript = Script(redeemScriptData, includesLength: false)
            if redeemScript.scriptType != .witnessV0KeyHash && redeemScript.scriptType != .witnessV0ScriptHash {
                let finalScript = Script(scriptSig.ops.dropLast() + redeemScript.ops)
                var stack2 = [Data]()
                return finalScript.run(stack: &stack2, tx: self, prevOuts: prevOuts, inIdx: inIdx)
            }
            scriptSig2 = redeemScript
        case .witnessV0KeyHash, .witnessV0ScriptHash, .witnessV1TapRoot:
            scriptSig2 = scriptSig
        }
        switch scriptSig.scriptType {
        case .witnessV0KeyHash:
            let witnessProgram = scriptSig2.segwitProgram
            var stack = witnessData[inIdx].stack
            let script = Script.scriptCodeV0(witnessProgram)
            return script.run(stack: &stack, tx: self, prevOuts: prevOuts, inIdx: inIdx)
        case .witnessV0ScriptHash:
            var stack = witnessData[inIdx].stack
            guard let witnessScriptRaw = stack.popLast() else {
                fatalError()
            }
            let witnessScript = Script(witnessScriptRaw, version: .v0, includesLength: false)
            return witnessScript.run(stack: &stack, tx: self, prevOuts: prevOuts, inIdx: inIdx)
        case .witnessV1TapRoot:
            fatalError("TODO")
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown, .scriptHash:
            fatalError()
        }
    }
}
