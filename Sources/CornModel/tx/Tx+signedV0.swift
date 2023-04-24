import Foundation

public extension Tx {
    
    func signedV0(privKey: Data, pubKey: Data, sigHashType: SigHashType, inIdx: Int, prevOut: Tx.Out) -> Tx {
        let scriptCode = ScriptV0.keyHashScript(hash160(pubKey))
        let sigHash = sigHashV0(sigHashType, inIdx: inIdx, prevOut: prevOut, scriptCode: scriptCode, opIdx: 0)
        let sig = signECDSA(msg: sigHash, privKey: privKey) + sigHashType.data
        
        var newWitnesses = [Witness]()
        ins.enumerated().forEach { i, _ in
            if i == inIdx {
                newWitnesses.append(.init(stack: [
                    sig,
                    pubKey
                ]))
            } else {
                newWitnesses.append(.init(stack: []))
            }
        }
        return .init(version: version, ins: ins, outs: outs, witnessData: newWitnesses, lockTime: lockTime)
    }
    
    func sigHashV0(_ type: SigHashType, inIdx: Int, prevOut: Tx.Out, scriptCode: ScriptV0, opIdx: Int) -> Data {
        // if the witnessScript contains any OP_CODESEPARATOR, the scriptCode is the witnessScript but removing everything up to and including the last executed OP_CODESEPARATOR before the signature checking opcode being executed, serialized as scripts inside CTxOut.
        var scriptCode = scriptCode
        scriptCode.removeSubScripts(before: opIdx)
        let amount = prevOut.value
        return hash256(sigMsgV0(sigHashType: type, inIdx: inIdx, scriptCode: scriptCode, amount: amount))
    }

    /// SegWit v0 signature message (sigMsg). More at https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#specification .
    func sigMsgV0(sigHashType: SigHashType, inIdx: Int, scriptCode: ScriptV0, amount: UInt64) -> Data {
        
        //If the ANYONECANPAY flag is not set, hashPrevouts is the double SHA256 of the serialization of all input outpoints;
        // Otherwise, hashPrevouts is a uint256 of 0x0000......0000.
        var hashPrevouts: Data
        if sigHashType.isAnyCanPay {
            hashPrevouts = Data(repeating: 0, count: 256)
        } else {
            let prevouts = ins.reduce(Data()) { $0 + $1.prevoutData }
            hashPrevouts = hash256(prevouts)
        }
        
        // If none of the ANYONECANPAY, SINGLE, NONE sighash type is set, hashSequence is the double SHA256 of the serialization of nSequence of all inputs;
        // Otherwise, hashSequence is a uint256 of 0x0000......0000.
        let hashSequence: Data
        if !sigHashType.isAnyCanPay && !sigHashType.isSingle && !sigHashType.isNone {
            let sequence = ins.reduce(Data()) {
                $0 + withUnsafeBytes(of: $1.sequence) { Data($0) }
            }
            hashSequence = hash256(sequence)
        } else {
            hashSequence = Data(repeating: 0, count: 256)
        }
        
        let outpointData = ins[inIdx].prevoutData
        
        let scriptCodeData = scriptCode.data.varLenData
        
        let amountData = withUnsafeBytes(of: amount) { Data($0) }
        let sequenceData = withUnsafeBytes(of: ins[inIdx].sequence) { Data($0) }
        
        // If the sighash type is neither SINGLE nor NONE, hashOutputs is the double SHA256 of the serialization of all output amount (8-byte little endian) with scriptPubKey (serialized as scripts inside CTxOuts);
        // If sighash type is SINGLE and the input index is smaller than the number of outputs, hashOutputs is the double SHA256 of the output amount with scriptPubKey of the same index as the input;
        // Otherwise, hashOutputs is a uint256 of 0x0000......0000.[7]
        let hashOuts: Data
        if !sigHashType.isSingle && !sigHashType.isNone {
            let outsData = outs.reduce(Data()) { $0 + $1.data }
            hashOuts = hash256(outsData)
        } else if sigHashType.isSingle && inIdx < outs.count {
            hashOuts = hash256(outs[inIdx].data)
        } else {
            hashOuts = Data(repeating: 0, count: 256)
        }
        
        let lockTimeData = withUnsafeBytes(of: lockTime) { Data($0) }
        
        let remaindingData = sequenceData + hashOuts + lockTimeData + sigHashType.data32
        return version.data + hashPrevouts + hashSequence + outpointData + scriptCodeData + amountData + remaindingData
    }
}
