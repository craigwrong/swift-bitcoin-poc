import Foundation

extension ScriptLegacy {

    public static func makeNullData(_ message: String) -> Self {
        guard let messageData = message.data(using: .utf8) else {
            fatalError()
        }
        return .withType(.nullData, data: [messageData])
    }

    public static func makeP2PK(pubKey: Data) -> Self {
        .withType(.pubKey, data: [pubKey])
    }
    
    public static func makeP2PKH(pubKey: Data) -> Self {
        .withType(.pubKeyHash, data: [hash160(pubKey)])
    }
    
    public static func makeP2SH(redeemScript: ScriptLegacy) -> Self {
        .withType(.scriptHash, data: [hash160(redeemScript.data)])
    }

    public static func makeP2WKH(pubKey: Data) -> Self {
        .withType(.witnessV0KeyHash, data: [hash160(pubKey)])
    }
    
    public static func makeP2WSH(redeemScriptV0: ScriptV0) -> Self {
        .withType(.witnessV0ScriptHash, data: [sha256(redeemScriptV0.data)])
    }

    public static func makeP2TR(outputKey: Data) -> Self {
        .withType(.witnessV1TapRoot, data: [outputKey])
    }

    static func withType(_ type: LockScriptType, data: [Data]) -> Self {
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
}
