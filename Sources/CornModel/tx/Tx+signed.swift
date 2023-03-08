import Foundation

public extension Tx {
    
    func signed(privKey: Data, pubKey: Data, redeemScript: Script? = .none,
                inIdx: Int, prevOut: Tx.Out, sigHashType: SigHashType) -> Tx {
        let sigHash = sigHash(sigHashType: sigHashType, inIdx: inIdx, prevOut: prevOut, redeemScript: redeemScript)
        
        let sig = signECDSA(msg: sigHash, privKey: privKey) // grind: false)
        let sigSigHashType = sig + sigHashType.data
        
        let input = ins[inIdx]
        
        let newScriptSig: Script
        if prevOut.scriptPubKey.scriptType == .pubKey {
            newScriptSig = .init(ops: [.pushBytes(sigSigHashType)])
        } else if prevOut.scriptPubKey.scriptType == .pubKeyHash {
            newScriptSig = .init(ops: [
                .pushBytes(sigSigHashType),
                .pushBytes(pubKey)
            ])
        } else { // if prevOut.scriptPubKey.scriptType == .scriptHash {
            let currentOps = input.scriptSig.ops
            newScriptSig = .init(
                ops: [
                    .pushBytes(sigSigHashType),
                ] +
                (currentOps.isEmpty ? [.pushBytes(redeemScript!.data(includeLength: false))] : []) +
                currentOps
            )
        }
        
        let signedIn = Tx.In(
            txID: input.txID,
            outIdx: input.outIdx,
            scriptSig: newScriptSig,
            sequence: input.sequence
        )
        
        var newIns = [In]()
        ins.enumerated().forEach { i, input in
            if i == inIdx {
                newIns.append(signedIn)
            } else {
                newIns.append(input)
            }
        }
        return .init(version: version, ins: newIns, outs: outs, witnessData: witnessData, lockTime: lockTime)
    }
    
    
    func sigHash(sigHashType: SigHashType, inIdx: Int, prevOut: Tx.Out, redeemScript: Script?) -> Data {
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let scriptCode: Script
        if prevOut.scriptPubKey.scriptType == .pubKey || prevOut.scriptPubKey.scriptType == .pubKeyHash {
            scriptCode = prevOut.scriptPubKey
        } else if prevOut.scriptPubKey.scriptType == .scriptHash, let redeemScript {
            scriptCode = redeemScript
        } else {
            fatalError("Invalid legacy previous output or redeem script not provided.")
        }
        let sigMsg = sigMsg(inIdx: inIdx, scriptCode: scriptCode, sigHashType: sigHashType)
        return hash256(sigMsg)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func sigMsg(inIdx: Int, scriptCode: Script, sigHashType: SigHashType) -> Data {
        let subScript = scriptCode // TODO: Account for code separators and FindAndDelete of sigs (not standard).
        var newIns = [Tx.In]()
        if sigHashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newIns.append(.init(txID: ins[inIdx].txID, outIdx: ins[inIdx].outIdx, scriptSig: subScript, sequence: ins[inIdx].sequence))
        } else {
            ins.enumerated().forEach { i, input in
                newIns.append(.init(
                    txID: input.txID,
                    outIdx: input.outIdx,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    scriptSig: i == inIdx ? subScript : .init(ops: []),
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: i == inIdx || sigHashType.isAll ? input.sequence : 0
                ))
            }
        }
        var newOuts: [Tx.Out]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if sigHashType.isSingle && inIdx >= outs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if sigHashType.isSingle {
            // The output of txCopy is resized to the size of the current input index+1.
            // All other txCopy outputs aside from the output that is the same as the current input index are set to a blank script and a value of (long) -1.
            newOuts = []
            
            outs.enumerated().forEach { i, out in
                guard i <= inIdx else {
                    return
                }
                if i == inIdx {
                    newOuts.append(out)
                } else if i < inIdx {
                    // TODO: Verify that "long -1" means  UInt64(bitPattern: -1) aka UInt64.max
                    newOuts.append(.init(value: UInt64.max, scriptPubKey: .init(ops: [])))
                }
            }
            
        } else if sigHashType.isNone {
            newOuts = []
        } else {
            newOuts = outs
        }
        let txCopy = Tx(
            version: version,
            ins: newIns,
            outs: newOuts,
            witnessData: [],
            lockTime: lockTime
        )
        return txCopy.data + sigHashType.data32
    }
    
    // TODO: Remove once newer implementation was tested.
    func sigMsgAlt(inIdx: Int, scriptCode subScript: Script, sigHashType: SigHashType) -> Data {
        let input = ins[inIdx]
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
            txCopy.ins = [input]
            txCopy.ins[0].scriptSig = subScript
        }
        return txCopy.data + sigHashType.data32
    }
}
