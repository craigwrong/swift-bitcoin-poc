import Foundation

public func makeNullData(_ message: String) -> [Op] {
    guard let messageData = message.data(using: .utf8) else {
        fatalError()
    }
    return [
        .return,
        messageData.count == 0 ? .zero : .pushBytes(messageData)
    ]
}

public func makeP2PK(pubKey: Data) -> [Op] {
    precondition(pubKey.count == 33)
    return [
        .pushBytes(pubKey),
        .checkSig
    ]
}

public func makeP2PKH(pubKey: Data) -> [Op] {
    [
        .dup,
        .hash160,
        .pushBytes(hash160(pubKey)),
        .equalVerify,
        .checkSig
    ]
}

public func makeP2MS(sigs: [Data], threshold: Int) -> [Op] {
    precondition(sigs.count <= UInt8.max && threshold <= sigs.count)
    let threshold = UInt8(1)
    return [
        .constant(threshold)
    ] + sigs.map { .pushBytes($0) } + [
        .constant(UInt8(sigs.count)),
        .checkMultiSig
    ]
}

public func makeP2SH(redeemScript: [Op]) -> [Op] {
    [
        .hash160,
        .pushBytes(hash160(redeemScript.data)),
        .equal
    ]
}

public func makeP2WKH(pubKey: Data) -> [Op] {
    [
        .zero,
        .pushBytes(hash160(pubKey))
    ]
}

public func makeP2WSH(redeemScriptV0: [Op]) -> [Op] {
    [
        .zero,
        .pushBytes(sha256(redeemScriptV0.data))
    ]
}

public func makeP2TR(outputKey: Data) -> [Op] {
    precondition(outputKey.count == 32)
    return .init([
        .constant(1),
        .pushBytes(outputKey)
    ])
}

func makeP2WPKH(_ pubKeyHash: Data) -> [Op] {
    // For P2WPKH witness program, the scriptCode is 0x1976a914{20-byte-pubkey-hash}88ac.
    // OP_DUP OP_HASH160 1d0f172a0ecb48aee1be1f2687d2963ae33f71a1 OP_EQUALVERIFY OP_CHECKSIG
    [
        .dup,
        .hash160,
        .pushBytes(pubKeyHash), // prevOut.scriptPubKey.ops[1], // pushBytes 20
        .equalVerify,
        .checkSig
    ]
}
