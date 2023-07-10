enum OutputType: Equatable {
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
