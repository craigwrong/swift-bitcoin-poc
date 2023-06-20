import Foundation

// [BIP112](https://github.com/bitcoin/bips/blob/master/bip-0112.mediawiki)
func opCheckSequenceVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    let first = try getUnaryParam(&stack, keep: true)
    
    guard
        first.count < 6,
        let sequence64 = first.asInt64,
        sequence64 >= 0,
        sequence64 <= UInt32.max
    else { throw ScriptError.invalidScript }
    
    let sequence = InSequence(rawValue: UInt32(sequence64), txVersion: .v2)
    if sequence.isLocktimeDisabled { return }
    
    if context.tx.version == .v1 { throw ScriptError.invalidScript }

    let txSequence = context.tx.ins[context.inIdx].sequence
    if txSequence.isLocktimeDisabled { throw ScriptError.invalidScript }

    guard sequence.isLocktimeHeight && txSequence.isLocktimeHeight && sequence.locktimeHeight <= txSequence.locktimeHeight || (
        sequence.isLocktimeClock && txSequence.isLocktimeClock && sequence.locktimeSeconds <= txSequence.locktimeSeconds
    ) else { throw ScriptError.invalidScript }
}
