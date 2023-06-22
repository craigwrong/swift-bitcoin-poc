extension Script {
    enum LockType: Equatable {
        case nonStandard,
             pubKey,
             pubKeyHash,
             scriptHash,
             multiSig,
             nullData,
             witnessV0KeyHash,
             witnessV0ScriptHash,
             witnessV1TapRoot,
             witnessUnknown
    }
}
