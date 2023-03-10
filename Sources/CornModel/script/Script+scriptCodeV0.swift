import Foundation

extension Script {
    
    static func scriptCodeV0(_ pubKeyHash: Data) -> Self {
        // For P2WPKH witness program, the scriptCode is 0x1976a914{20-byte-pubkey-hash}88ac.
        // OP_DUP OP_HASH160 1d0f172a0ecb48aee1be1f2687d2963ae33f71a1 OP_EQUALVERIFY OP_CHECKSIG
        .init([
            .dup,
            .hash160,
            .pushBytes(pubKeyHash), // prevOut.scriptPubKey.ops[1], // pushBytes 20
            .equalVerify,
            .checkSig
        ], version: .v0)
    }
}
