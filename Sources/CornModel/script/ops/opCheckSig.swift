import Foundation

func opCheckSig(_ sig: Data, _ pubKey: Data, stack: inout [Data], context: ExecutionContext) -> Bool {
    let result: Bool
    switch context.version {
        case .legacy:
        // Legacy semantics
        result = context.tx.checkSig(sig, pubKey: pubKey, inIdx: context.inIdx, prevOut: context.prevOut, script: context.script, opIdx: context.opIdx)
        case .witnessV0:
        // SegWit V0 semantics
        result = context.tx.checkSigV0(sig, pubKey: pubKey, inIdx: context.inIdx, prevOut: context.prevOut, script: context.script, opIdx: context.opIdx)
        case .witnessV1:
        guard let leafVersion = context.leafVersion, let keyVersion = context.keyVersion else {
            preconditionFailure()
        }
        let tapLeafHash = taggedHash(tag: "TapLeaf", payload: Data([leafVersion]) + context.script.data.varLenData)
        
        // https://bitcoin.stackexchange.com/questions/115695/what-are-the-last-bytes-for-in-a-taproot-script-path-sighash
        var codesepPos = UInt32(0xffffffff)
        var i = 0
        while i <= context.opIdx {
            if context.script[i] == .codeSeparator {
                codesepPos = UInt32(i)
            }
            i += 1
        }
        
        // Tapscript semantics
        result = context.tx.checkSigV1(sig, pubKey: pubKey, inIdx: context.inIdx, prevOuts: context.prevOuts, extFlag: 1, tapscriptExt: .init(tapLeafHash: tapLeafHash, keyVersion: keyVersion, codesepPos: codesepPos))
    }
    stack.pushInt(result ? 1 : 0)
    return true
}
