public enum LockScriptType: Equatable {
    case nonStandard,
         pubKey,
         pubKeyHash,
         scriptHash,
         multiSig(Int, Int),
         nullData,
         witnessV0KeyHash,
         witnessV0ScriptHash,
         witnessV1TapRoot,
         witnessUnknown
}
