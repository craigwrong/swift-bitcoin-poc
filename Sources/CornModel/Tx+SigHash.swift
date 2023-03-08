import Foundation

public extension Tx {
    
    func checkSigLegacy(_ sigWithHashType: Data, pubKey: Data, inIdx: Int, prevOut: Tx.Out, redeemScript: Script?) -> Bool {
        var sig = sigWithHashType
        guard let hashTypeRaw = sig.popLast(), let hashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHashLegacy(sigHashType: hashType, inIdx: inIdx, prevOut: prevOut, redeemScript: redeemScript)
        let result = CornModel.verifyWithPubKey(sig: sig, msg: sigHash, pubKey: pubKey)
        return result
    }
    
    func checkSigLegacy(_ sigWithHashType: Data, secretKey: Data, inIdx: Int, prevOut: Tx.Out, redeemScript: Script?) -> Bool {
        var sig = sigWithHashType
        guard let hashTypeRaw = sig.popLast(), let hashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = sigHashLegacy(sigHashType: hashType, inIdx: inIdx, prevOut: prevOut, redeemScript: redeemScript)
        return CornModel.verifyWithSecretKey(sig: sig, msg: sigHash, secretKey: secretKey)
    }

    func signed(secretKey: Data, pubKey: Data, redeemScript: Script? = .none, inIdx: Int, prevOuts: [Tx.Out], sigHashType: SigHashType) -> Tx {
        switch(prevOuts[inIdx].scriptPubKey.scriptType) {
        case .nonStandard:
            fatalError("Signing of non-standard scripts is not implemented.")
        case .pubKey, .pubKeyHash:
            return signedLegacy(secretKey: secretKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .scriptHash:
            guard let redeemScript else {
                fatalError("Missing required redeem script.")
            }
            if redeemScript.scriptType == .witnessV0KeyHash {
                // TODO: Pass redeem script on to add to input's script sig
                var withScriptSig = self
                withScriptSig.ins[inIdx].scriptSig = .init(ops: [.pushBytes(redeemScript.data(includeLength: false))])
                return withScriptSig.signedWitnessV0(secretKey: secretKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
            }
            // TODO: Handle P2SH-P2WSH
            return signedLegacy(secretKey: secretKey, pubKey: pubKey, redeemScript: redeemScript, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .multiSig:
            fatalError("Signing of legacy multisig transactions is not yet implemented.")
        case .nullData:
            fatalError("Null data script transactions cannot be signed nor spent.")
        case .witnessV0KeyHash:
            return signedWitnessV0(secretKey: secretKey, pubKey: pubKey, inIdx: inIdx, prevOut: prevOuts[inIdx], sigHashType: sigHashType)
        case .witnessV0ScriptHash:
            fatalError("Signing of P2WSH transactions is not yet implemented.")
        case .witnessV1TapRoot:
            return signedWitnessV1(secretKey: secretKey, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts, sigHashType: sigHashType)
        case .witnessUnknown:
            fatalError("Signing of transactions with witness script version higher than 1 is not yet implemented.")
        }
    }

    func sigHashLegacy(sigHashType: SigHashType, inIdx: Int, prevOut: Tx.Out, redeemScript: Script?) -> Data {
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let scriptCode: Script
        if prevOut.scriptPubKey.scriptType == .pubKey || prevOut.scriptPubKey.scriptType == .pubKeyHash {
            scriptCode = prevOut.scriptPubKey
        } else if prevOut.scriptPubKey.scriptType == .scriptHash, let redeemScript {
            scriptCode = redeemScript
        } else {
            fatalError("Invalid legacy previous output or redeem script not provided.")
        }
        let sigMsg = sigMsgLegacy(inIdx: inIdx, scriptCode: scriptCode, sigHashType: sigHashType)
        return doubleHash(sigMsg)
    }

    func signedLegacy(secretKey: Data, pubKey: Data, redeemScript: Script? = .none,
                      inIdx: Int, prevOut: Tx.Out, sigHashType: SigHashType) -> Tx {
        let sigHash = sigHashLegacy(sigHashType: sigHashType, inIdx: inIdx, prevOut: prevOut, redeemScript: redeemScript)
        
        let sig = sign(msg: sigHash, secretKey: secretKey) // grind: false)
        let sigWithHashType = sig + sigHashType.data
        
        let currentInput = ins[inIdx]
        
        let newScriptSig: Script
        if prevOut.scriptPubKey.scriptType == .pubKey {
            newScriptSig = .init(ops: [.pushBytes(sigWithHashType)])
        } else if prevOut.scriptPubKey.scriptType == .pubKeyHash {
            newScriptSig = .init(ops: [
                .pushBytes(sigWithHashType),
                .pushBytes(pubKey)
            ])
        } else { // if prevOut.scriptPubKey.scriptType == .scriptHash {
            let currentOps = currentInput.scriptSig.ops
            newScriptSig = .init(
                ops: [
                    .pushBytes(sigWithHashType),
                ] +
                (currentOps.isEmpty ? [.pushBytes(redeemScript!.data(includeLength: false))] : []) +
                currentOps
            )
        }
        
        let signedInput = Tx.In(
            txID: currentInput.txID,
            output: currentInput.output,
            scriptSig: newScriptSig,
            sequence: currentInput.sequence
        )
        
        var newInputs = [In]()
        ins.enumerated().forEach { index, input in
            if index == inIdx {
                newInputs.append(signedInput)
            } else {
                newInputs.append(input)
            }
        }
        return .init(version: version, ins: newInputs, outs: outs, witnessData: witnessData, lockTime: lockTime)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func sigMsgLegacy(inIdx: Int, scriptCode: Script, sigHashType: SigHashType) -> Data {
        let subScript = scriptCode // TODO: Account for code separators and FindAndDelete of sigs (not standard).
        var newInputs = [Tx.In]()
        if sigHashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newInputs.append(.init(txID: ins[inIdx].txID, output: ins[inIdx].output, scriptSig: subScript, sequence: ins[inIdx].sequence))
        } else {
            ins.enumerated().forEach { index, input in
                newInputs.append(.init(
                    txID: input.txID,
                    output: input.output,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    scriptSig: index == inIdx ? subScript : .init(ops: []),
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: index == inIdx || sigHashType.isAll ? input.sequence : 0
                ))
            }
        }
        var newOutputs: [Tx.Out]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if sigHashType.isSingle && inIdx >= outs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if sigHashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOutputs = []
            
            outs.enumerated().forEach { index, output in
                guard index <= inIdx else {
                    return
                }
                if index == inIdx {
                    newOutputs.append(output)
                } else if index < inIdx {
                    // TODO: Verify that "long -1" means  UInt64(bitPattern: -1) aka UInt64.max
                    newOutputs.append(.init(value: UInt64.max, scriptPubKey: .init(ops: [])))
                }
            }
            
        } else if sigHashType.isNone {
            newOutputs = []
        } else {
            newOutputs = outs
        }
        let txCopy = Tx(
            version: version,
            ins: newInputs,
            outs: newOutputs,
            witnessData: [],
            lockTime: lockTime
        )
        return txCopy.data + sigHashType.data32
    }

    func sigMsgLegacy2(inIdx: Int, scriptCode subScript: Script, sigHashType: SigHashType) -> Data {
        let currentInput = ins[inIdx]
        var txCopy = self
        txCopy.witnessData = []
        txCopy.ins.indices.forEach {
            txCopy.ins[$0].scriptSig = .init(ops: [])
        }
        txCopy.ins[inIdx].scriptSig = subScript
        if sigHashType.isNone {
            txCopy.outs = []
        } else if sigHashType.isSingle {
            txCopy.outs = []
            outs.enumerated().forEach { (i, out) in
                if i == inIdx {
                    txCopy.outs.append(out)
                } else if i < inIdx {
                    txCopy.outs.append(.init(value: UInt64.max, scriptPubKey: .init(ops: [])))
                }
            }
        }
        if sigHashType.isNone || sigHashType.isSingle {
            txCopy.ins.indices.forEach {
                if $0 != inIdx {
                    txCopy.ins[$0].sequence = 0
                }
            }
        }
        if sigHashType.isAnyCanPay {
            txCopy.ins = [currentInput]
            txCopy.ins[0].scriptSig = subScript
        }
        return txCopy.data + sigHashType.data32
    }
}
