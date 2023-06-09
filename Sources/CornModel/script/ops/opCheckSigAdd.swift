import Foundation

///
/// pk0, checksig, pk1, checksigadd, pk2, checksigadd, 3, equal
func opCheckSigAdd(_ stack: inout [Data], context: ExecutionContext) throws {

    guard let tapLeafHash = context.tapLeafHash, let keyVersion = context.keyVersion else {
        preconditionFailure()
    }

    // If fewer than 3 elements are on the stack, the script MUST fail and terminate immediately.
    let (sig, nData, pubKey) = try getTernaryParams(&stack)

    if nData.count > 4 || pubKey.isEmpty {
        // - If n is larger than 4 bytes, the script MUST fail and terminate immediately.
        // - If the public key size is zero, the script MUST fail and terminate immediately.
        throw ScriptError.invalidScript
    }

    // If the public key size is not zero and not 32 bytes, the public key is of an unknown public key type and no actual signature verification is applied. During script execution of signature opcodes they behave exactly as known public key types except that signature validation is considered to be successful.
        

    if pubKey.count == 32 && !sig.isEmpty {
        // If the public key size is 32 bytes, it is considered to be a public key as described in BIP340:
    
        // If the signature is not the empty vector, the signature is validated against the public key (see the next subsection). Validation failure in this case immediately terminates script execution with failure.

        // https://bitcoin.stackexchange.com/questions/115695/what-are-the-last-bytes-for-in-a-taproot-script-path-sighash
        var codesepPos = UInt32(0xffffffff)
        var i = 0
        while i <= context.opIdx {
            if context.script[i] == .codeSeparator { codesepPos = UInt32(i) }
            i += 1
        }
        
        // Tapscript semantics
        let result = context.tx.checkSigV1(sig, pubKey: pubKey, inIdx: context.inIdx, prevOuts: context.prevOuts, extFlag: 1, tapscriptExt: .init(tapLeafHash: tapLeafHash, keyVersion: keyVersion, codesepPos: codesepPos))
        
        if !result {
            throw ScriptError.invalidScript
        }
    }
    // If the public key size is not zero and not 32 bytes, the public key is of an unknown public key type and no actual signature verification is applied. During script execution of signature opcodes they behave exactly as known public key types except that signature validation is considered to be successful.

    // If the script did not fail and terminate before this step, regardless of the public key type:
    if sig.isEmpty {
        // If the signature is the empty vector:
        // For OP_CHECKSIGADD, a CScriptNum with value n is pushed onto the stack, and execution continues with the next opcode.
        stack.append(nData)
    } else {
        // If the signature is not the empty vector, the opcode is counted towards the sigops budget (see further).
        // For OP_CHECKSIGADD, a CScriptNum with value of n + 1 is pushed onto the stack.
        let paddedN = nData + Data(repeating: 0, count: MemoryLayout<UInt32>.size - nData.count)
        let nPlus1 = paddedN.withUnsafeBytes { $0.load(as: UInt32.self) } + 1
        stack.append(withUnsafeBytes(of: nPlus1) { Data($0) })
    }
}
