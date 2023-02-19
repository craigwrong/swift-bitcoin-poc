import Foundation

public extension Tx {
    
    func checkSigLegacy(_ signatureWithHashType: Data, privateKey: Data, inputIndex: Int, previousTxOut: Tx.Out, redeemScript: Script?) -> Bool {
        var signature = signatureWithHashType
        guard let hashTypeRaw = signature.popLast(), let hashType = SigHashType(rawValue: hashTypeRaw) else {
            fatalError()
        }
        let sigHash = signatureHashLegacy(sigHashType: hashType, inputIndex: inputIndex, previousTxOut: previousTxOut, redeemScript: redeemScript)
        return verify(signature: signature, message: sigHash, privateKey: privateKey)
    }
    
    func signed(privateKey: Data, publicKey: Data, redeemScript: Script? = .none, inputIndex: Int, previousTxOut: Tx.Out, sigHashType: SigHashType) -> Tx {
        switch(previousTxOut.scriptPubKey.scriptType) {
        case .nonStandard:
            fatalError("Signing of non-standard scripts is not implemented.")
        case .pubKey, .pubKeyHash:
            return signedLegacy(privateKey: privateKey, publicKey: publicKey, inputIndex: inputIndex, previousTxOut: previousTxOut, sigHashType: sigHashType)
        case .scriptHash:
            guard let redeemScript else {
                fatalError("Missing required redeem script.")
            }
            if redeemScript.scriptType == .witnessV0KeyHash {
                // TODO: Pass redeem script on to add to input's script sig
                var withScriptSig = self
                withScriptSig.ins[inputIndex].scriptSig = .init(ops: [.pushBytes(redeemScript.data(includeLength: false))])
                return withScriptSig.signedWitnessV0(privateKey: privateKey, publicKey: publicKey, inputIndex: inputIndex, previousTxOut: previousTxOut, sigHashType: sigHashType)
            }
            // TODO: Handle P2SH-P2WSH
            return signedLegacy(privateKey: privateKey, publicKey: publicKey, redeemScript: redeemScript, inputIndex: inputIndex, previousTxOut: previousTxOut, sigHashType: sigHashType)
        case .multiSig:
            fatalError("Signing of legacy multisig transactions is not yet implemented.")
        case .nullData:
            fatalError("Null data script transactions cannot be signed nor spent.")
        case .witnessV0KeyHash:
            return signedWitnessV0(privateKey: privateKey, publicKey: publicKey, inputIndex: inputIndex, previousTxOut: previousTxOut, sigHashType: sigHashType)
        case .witnessV0ScriptHash:
            fatalError("Signing of P2WSH transactions is not yet implemented.")
        case .witnessV1TapRoot:
            fatalError("Signing of taproot transactions is not yet implemented.")
        case .witnessUnknown:
            fatalError("Signing of transactions with witness script version higher than 1 is not yet implemented.")
        }
    }

    func signatureHashLegacy(sigHashType: SigHashType, inputIndex: Int, previousTxOut: Tx.Out, redeemScript: Script?) -> Data {
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let scriptCode: Script
        if previousTxOut.scriptPubKey.scriptType == .pubKey || previousTxOut.scriptPubKey.scriptType == .pubKeyHash {
            scriptCode = previousTxOut.scriptPubKey
        } else if previousTxOut.scriptPubKey.scriptType == .scriptHash, let redeemScript {
            scriptCode = redeemScript
        } else {
            fatalError("Invalid legacy previous output or redeem script not provided.")
        }
        let preImage = signatureMessageLegacy(inputIndex: inputIndex, scriptCode: scriptCode, sigHashType: sigHashType)
        return doubleHash(preImage)
    }

    func signedLegacy(privateKey: Data, publicKey: Data, redeemScript: Script? = .none,
                      inputIndex: Int, previousTxOut: Tx.Out, sigHashType: SigHashType) -> Tx {
        let sigHash = signatureHashLegacy(sigHashType: sigHashType, inputIndex: inputIndex, previousTxOut: previousTxOut, redeemScript: redeemScript)
        
        let signature = sign(message: sigHash, privateKey: privateKey) // grind: false)
        let signatureWithHashType = signature + sigHashType.data
        
        let currentInput = ins[inputIndex]
        
        let newScriptSig: Script
        if previousTxOut.scriptPubKey.scriptType == .pubKey {
            newScriptSig = .init(ops: [.pushBytes(signatureWithHashType)])
        } else if previousTxOut.scriptPubKey.scriptType == .pubKeyHash {
            newScriptSig = .init(ops: [
                .pushBytes(signatureWithHashType),
                .pushBytes(publicKey)
            ])
        } else { // if previousTxOut.scriptPubKey.scriptType == .scriptHash {
            let currentOps = currentInput.scriptSig.ops
            newScriptSig = .init(
                ops: [
                    .pushBytes(signatureWithHashType),
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
            if index == inputIndex {
                newInputs.append(signedInput)
            } else {
                newInputs.append(input)
            }
        }
        return .init(version: version, ins: newInputs, outs: outs, witnessData: witnessData, lockTime: lockTime)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func signatureMessageLegacy(inputIndex: Int, scriptCode: Script, sigHashType: SigHashType) -> Data {
        let subScript = scriptCode // TODO: Account for code separators and FindAndDelete of signatures (not standard).
        var newInputs = [Tx.In]()
        if sigHashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newInputs.append(.init(txID: ins[inputIndex].txID, output: ins[inputIndex].output, scriptSig: subScript, sequence: ins[inputIndex].sequence))
        } else {
            ins.enumerated().forEach { index, input in
                newInputs.append(.init(
                    txID: input.txID,
                    output: input.output,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    scriptSig: index == inputIndex ? subScript : .init(ops: []),
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: index == inputIndex || sigHashType.isAll ? input.sequence : 0
                ))
            }
        }
        var newOutputs: [Tx.Out]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if sigHashType.isSingle && inputIndex >= outs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if sigHashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOutputs = []
            
            outs.enumerated().forEach { index, output in
                guard index <= inputIndex else {
                    return
                }
                if index == inputIndex {
                    newOutputs.append(output)
                } else if index < inputIndex {
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

    func signatureMessageLegacy2(inputIndex: Int, scriptCode subScript: Script, sigHashType: SigHashType) -> Data {
        let currentInput = ins[inputIndex]
        var txCopy = self
        txCopy.witnessData = []
        txCopy.ins.indices.forEach {
            txCopy.ins[$0].scriptSig = .init(ops: [])
        }
        txCopy.ins[inputIndex].scriptSig = subScript
        if sigHashType.isNone {
            txCopy.outs = []
        } else if sigHashType.isSingle {
            txCopy.outs = []
            outs.enumerated().forEach { (i, out) in
                if i == inputIndex {
                    txCopy.outs.append(out)
                } else if i < inputIndex {
                    txCopy.outs.append(.init(value: UInt64.max, scriptPubKey: .init(ops: [])))
                }
            }
        }
        if sigHashType.isNone || sigHashType.isSingle {
            txCopy.ins.indices.forEach {
                if $0 != inputIndex {
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
