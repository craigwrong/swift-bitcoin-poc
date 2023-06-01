import Foundation

enum CoreScriptType: String, Equatable, Decodable {
    case nonStandard = "nonstandard",
         pubKey = "pubkey",
         pubKeyHash = "pubkeyhash",
         scriptHash = "scripthash",
         multiSig = "multisig",
         nullData = "nulldata",
         witnessV0KeyHash = "witness_v0_keyhash",
         witnessV0ScriptHash = "witness_v0_scripthash",
         witnessV1TapRoot = "witness_v1_taproot",
         witnessUnknown = "witness_unknown"
}

extension CoreScriptType {
    
    init(_ scriptType: LockScriptType) {
        switch scriptType {
        case .nonStandard:
            self = .nonStandard
        case .pubKey:
            self = .pubKey
        case .pubKeyHash:
            self = .pubKeyHash
        case .scriptHash:
            self = .scriptHash
        case .multiSig(_, _):
            self = .multiSig
        case .nullData:
            self = .nullData
        case .witnessV0KeyHash:
            self = .witnessV0KeyHash
        case .witnessV0ScriptHash:
            self = .witnessV0ScriptHash
        case .witnessV1TapRoot:
            self = .witnessV1TapRoot
        case .witnessUnknown:
            self = .witnessUnknown
        }
    }
}
