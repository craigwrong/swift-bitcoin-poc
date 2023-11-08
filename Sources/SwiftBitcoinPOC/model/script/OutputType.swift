enum OutputType: Equatable {
    case nonStandard,
         publicKey,
         publicKeyHash,
         scriptHash,
         multiSig,
         nullData,
         witnessV0KeyHash,
         witnessV0ScriptHash,
         witnessV1TapRoot,
         witnessUnknown
}
