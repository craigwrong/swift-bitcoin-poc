import Foundation

public extension Tx {
    
    mutating func sign(privKey: Data, pubKey: Data, redeemScript: ScriptLegacy? = .none, hashType: HashType, inIdx: Int, prevOut: Tx.Out) {
        //let pubKey = pubKey ?? getPubKey(privKey: privKey)
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
    
    
    func sigHash(_ type: HashType, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptLegacy, opIdx: Int) -> Data {
        
        // the scriptCode is the actually executed script - either the scriptPubKey for non-segwit, non-P2SH scripts, or the redeemscript in non-segwit P2SH scripts
        let subScript: ScriptLegacy
        if prevOut.scriptPubKey.scriptType == .pubKey || prevOut.scriptPubKey.scriptType == .pubKeyHash {
            // TODO: Account for code separators. Find the last executed one and remove anything before it. After that, remove all remaining OP_CODESEPARATOR instances from script code
            var scriptCode = scriptCode
            scriptCode.removeSubScripts(before: opIdx)
            scriptCode.removeCodeSeparators()
            subScript = scriptCode
            // TODO: FindAndDelete any signature data in subScript (coming scriptPubKey, not standard to have sigs there anyway).
        } else if prevOut.scriptPubKey.scriptType == .scriptHash {
            let input = ins[inIdx]
            guard let op = input.scriptSig?.ops.last, case let .pushBytes(redeemScriptRaw) = op else {
                preconditionFailure()
            }
            subScript = ScriptLegacy(redeemScriptRaw)
        } else {
            fatalError("Invalid legacy previous output or redeem script not provided.")
        }
        let sigMsg = sigMsg(hashType: type, inIdx: inIdx, subScript: subScript)
        return hash256(sigMsg)
    }
    
    /// https://en.bitcoin.it/wiki/OP_CHECKSIG
    func sigMsg(hashType: HashType, inIdx: Int, subScript: ScriptLegacy) -> Data {
        var newIns = [Tx.In]()
        if hashType.isAnyCanPay {
            // Procedure for Hashtype SIGHASH_ANYONECANPAY
            // The txCopy input vector is resized to a length of one.
            // The current transaction input (with scriptPubKey modified to subScript) is set as the first and only member of this vector.
            newIns.append(.init(txID: ins[inIdx].txID, outIdx: ins[inIdx].outIdx, sequence: ins[inIdx].sequence, scriptSig: subScript))
        } else {
            ins.enumerated().forEach { i, input in
                newIns.append(.init(
                    txID: input.txID,
                    outIdx: input.outIdx,
                    // SIGHASH_NONE | SIGHASH_SINGLE - All other txCopy inputs aside from the current input are set to have an nSequence index of zero.
                    sequence: i == inIdx || hashType.isAll ? input.sequence : 0,
                    // The scripts for all transaction inputs in txCopy are set to empty scripts (exactly 1 byte 0x00)
                    // The script for the current transaction input in txCopy is set to subScript (lead in by its length as a var-integer encoded!)
                    scriptSig: i == inIdx ? subScript : .init([])
                ))
            }
        }
        var newOuts: [Tx.Out]
        // Procedure for Hashtype SIGHASH_SINGLE
        
        //if hashType.isSingle && inIdx >= outs.count {
        // uint256 of 0x0000......0001 is committed if the input index for a SINGLE signature is greater than or equal to the number of outputs.
        //outs = Data(repeating: 0, count: 255) + [0x01]
        // TODO: figure out this
        //} else
        if hashType.isSingle {
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
                    newOuts.append(.init(value: UInt64.max, scriptPubKeyData: .init()))
                }
            }
            
        } else if hashType.isNone {
            newOuts = []
        } else {
            newOuts = outs
        }
        let txCopy = Tx(
            version: version,
            lockTime: lockTime,
            ins: newIns,
            outs: newOuts
        )
        return txCopy.data + hashType.data32
    }
    
    // TODO: Remove once newer implementation was tested.
    func sigMsgAlt(hashType: HashType, inIdx: Int, scriptCode subScript: ScriptLegacy) -> Data {
        let input = ins[inIdx]
        var txCopy = self
        txCopy.ins.indices.forEach {
            txCopy.ins[$0].scriptSig = .init([])
            txCopy.ins[$0].witness = .none
        }
        txCopy.ins[inIdx].scriptSig = subScript
        if hashType.isNone {
            txCopy.outs = []
        } else if hashType.isSingle {
            txCopy.outs = []
            outs.enumerated().forEach { (i, out) in
                if i == inIdx {
                    txCopy.outs.append(out)
                } else if i < inIdx {
                    txCopy.outs.append(.init(value: UInt64.max, scriptPubKeyData: .init()))
                }
            }
        }
        if hashType.isNone || hashType.isSingle {
            txCopy.ins.indices.forEach {
                if $0 != inIdx {
                    txCopy.ins[$0].sequence = 0
                }
            }
        }
        if hashType.isAnyCanPay {
            txCopy.ins = [input]
            txCopy.ins[0].scriptSig = subScript
        }
        return txCopy.data + hashType.data32
    }
}
