import Foundation
public extension Tx {
    func verify(prevOuts: [Tx.Out]) -> Bool {
        ins.indices.reduce(true) { result, i in
            result && verify(inIdx: i, prevOuts: prevOuts)
        }
    }
    
    func verify(inIdx: Int, prevOuts: [Tx.Out]) -> Bool {
        let input = ins[inIdx]
        let prevOut = prevOuts[inIdx]
        let scriptPubKey = prevOut.scriptPubKey
        
        let scriptPubKey2: Script
        switch prevOut.scriptPubKey.scriptType {
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown:
            var stack = [Data]()
            guard input.scriptSig.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts) else {
                return false
            }
            return prevOut.scriptPubKey.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .scriptHash:
            var stack = [Data]()
            guard
                let op = input.scriptSig.ops.last,
                Script([op]).run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts),
                prevOut.scriptPubKey.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
            else {
                return false
            }
            guard let lastOp = input.scriptSig.ops.last, case let .pushBytes(redeemScriptRaw) = lastOp else {
                fatalError()
            }
            let redeemScript = Script(redeemScriptRaw, includesLength: false)
            if redeemScript.scriptType != .witnessV0KeyHash && redeemScript.scriptType != .witnessV0ScriptHash {
                var stack2 = [Data]()
                guard
                    Script(input.scriptSig.ops.dropLast()).run(stack: &stack2, tx: self, inIdx: inIdx, prevOuts: prevOuts)
                else {
                    return false
                }
                return redeemScript.run(stack: &stack2, tx: self, inIdx: inIdx, prevOuts: prevOuts)
            }
            guard input.scriptSig.ops.count == 1 else {
                // The scriptSig must be exactly a push of the BIP16 redeemScript or validation fails. ("P2SH witness program")
                return false
            }
            scriptPubKey2 = redeemScript
        case .witnessV0KeyHash, .witnessV0ScriptHash, .witnessV1TapRoot:
            guard input.scriptSig.ops.count == 0 else {
                // The scriptSig must be exactly empty or validation fails. ("native witness program")
                return false
            }
            scriptPubKey2 = scriptPubKey
        }
        switch scriptPubKey2.scriptType {
        case .witnessV0KeyHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the hash of the public key
            var stack = witnessData[inIdx].stack
            return Script.v0KeyHashScript(witnessProgram).run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV0ScriptHash:
            let witnessProgram = scriptPubKey2.witnessProgram // In this case it is the sha256 of the witness script
            var stack = witnessData[inIdx].stack
            guard let witnessScriptRaw = stack.popLast() else {
                fatalError()
            }
            guard sha256(witnessScriptRaw) == witnessProgram else {
                return false
            }
            let witnessScript = Script(witnessScriptRaw, version: .v0, includesLength: false)
            return witnessScript.run(stack: &stack, tx: self, inIdx: inIdx, prevOuts: prevOuts)
        case .witnessV1TapRoot:
            fatalError("TODO")
        case .pubKey, .pubKeyHash, .multiSig, .nullData, .nonStandard, .witnessUnknown, .scriptHash:
            fatalError()
        }
    }
}
