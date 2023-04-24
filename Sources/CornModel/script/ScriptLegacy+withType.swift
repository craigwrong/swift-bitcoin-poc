import Foundation

extension ScriptLegacy {
    
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
            precondition(data.count == 3 && data[0].count == 20)
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
                .constant(0),
                .pushBytes(data[0])
            ])
        case .witnessV0ScriptHash:
            precondition(data.count == 1 && data[0].count == 32)
            return .init([
                .constant(0),
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
