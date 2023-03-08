import Foundation

public extension Script {
    
    enum ScriptType: String, Equatable, Decodable {
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
}
