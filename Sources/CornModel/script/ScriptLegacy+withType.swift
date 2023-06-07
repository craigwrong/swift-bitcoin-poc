import Foundation

public func makeNullData(_ message: String) -> [Op] {
    guard let messageData = message.data(using: .utf8) else {
        fatalError()
    }
    return scriptWithType(.nullData, data: [messageData])
}

public func makeP2PK(pubKey: Data) -> [Op] {
    scriptWithType(.pubKey, data: [pubKey])
}

public func makeP2PKH(pubKey: Data) -> [Op] {
    scriptWithType(.pubKeyHash, data: [hash160(pubKey)])
}

public func makeP2SH(redeemScript: [Op]) -> [Op] {
    scriptWithType(.scriptHash, data: [hash160(redeemScript.data)])
}

public func makeP2WKH(pubKey: Data) -> [Op] {
    scriptWithType(.witnessV0KeyHash, data: [hash160(pubKey)])
}

public func makeP2WSH(redeemScriptV0: [Op]) -> [Op] {
    scriptWithType(.witnessV0ScriptHash, data: [sha256(redeemScriptV0.data)])
}

public func makeP2TR(outputKey: Data) -> [Op] {
    scriptWithType(.witnessV1TapRoot, data: [outputKey])
}

func scriptWithType(_ type: LockScriptType, data: [Data]) -> [Op] {
    switch type {
    case .nonStandard, .witnessUnknown:
        fatalError()
    case .pubKey:
        precondition(data.count == 1 && data[0].count == 33)
        return .init([
            .pushBytes(data[0]),
            .checkSig
        ])
    case .pubKeyHash:
        precondition(data.count == 1 && data[0].count == 20)
        return .init([
            .dup,
            .hash160,
            .pushBytes(data[0]),
            .equalVerify,
            .checkSig
        ])
    case .scriptHash:
        precondition(data.count == 1 && data[0].count == 20)
        return .init([
            .hash160,
            .pushBytes(data[0]),
            .equal
        ])
    case .multiSig:
        precondition(data.count > 0 && data.count < 3) // TODO: Support arbitrary multisigs
        let threshold = UInt8(1)
        return .init([
            .constant(threshold),
            .pushBytes(data[0]),
            .constant(UInt8(data.count)),
            .checkMultiSig
        ])
    case .nullData:
        precondition(data.count == 1)
        return .init([
            .return,
            .pushBytes(data[0])
        ])
    case .witnessV0KeyHash:
        precondition(data.count == 1 && data[0].count == 20)
        return .init([
            .zero,
            .pushBytes(data[0])
        ])
    case .witnessV0ScriptHash:
        precondition(data.count == 1 && data[0].count == 32)
        return .init([
            .zero,
            .pushBytes(data[0])
        ])
    case .witnessV1TapRoot:
        precondition(data.count == 1 && data[0].count == 32)
        return .init([
            .constant(1),
            .pushBytes(data[0])
        ])
    }
}
