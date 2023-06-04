import Foundation

func opCheckSigV1(_ sig: Data, _ pubKey: Data, stack: inout [Data], tx: Tx, inIdx: Int, prevOuts: [Tx.Out], tapscript: ScriptV1, opIdx: Int) -> Bool {

    
    let tapLeafHash = tapscript.tapLeafHash
    
    // https://bitcoin.stackexchange.com/questions/115695/what-are-the-last-bytes-for-in-a-taproot-script-path-sighash
    var codesepPos = UInt32(0xffffffff)
    var i = 0
    while i <= opIdx {
        if tapscript.ops[i] == .codeSeparator {
            codesepPos = UInt32(i)
        }
        i += 1
    }
    
    // Tapscript semantics
    let result = tx.checkSigV1(sig, pubKey: pubKey, inIdx: inIdx, prevOuts: prevOuts, extFlag: 1, tapscriptExt: .init(tapLeafHash: tapLeafHash, keyVersion: tapscript.keyVersion, codesepPos: codesepPos))
    stack.pushInt(result ? 1 : 0)
    return true
}
