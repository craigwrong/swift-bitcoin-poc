import Foundation

func opCheckSequenceVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    // Note that elsewhere numeric opcodes are limited to
    // operands in the range -2**31+1 to 2**31-1, however it is
    // legal for opcodes to produce results exceeding that
    // range. This limitation is implemented by CScriptNum's
    // default 4-byte limit.
    //
    // Thus as a special case we tell CScriptNum to accept up
    // to 5-byte bignums, which are good until 2**39-1, well
    // beyond the 2**32-1 limit of the nSequence field itself.

    // In the rare event that the argument may be < 0 due to
    // some arithmetic being done first, you can always use
    // 0 MAX CHECKSEQUENCEVERIFY.
    let first = try getUnaryParam(&stack)
    guard first.count < 6, let sequence = first.asInt64, sequence >= 0 else {
        throw ScriptError.invalidScript
    }

    let sequenceLockTimeDisableFlag = Int64(1) << 31
    let sequenceLockTimeTypeFlag = Int64(1) << 22
    let sequenceLockTimeMask = Int64(0x000000000000ffff)
    // To provide for future soft-fork extensibility, if the
    // operand has the disabled lock-time flag set,
    // CHECKSEQUENCEVERIFY behaves as a NOP.
    if sequence & sequenceLockTimeDisableFlag != 0 {
        return
    }

    // Compare the specified sequence number with the input.
    // try checkSequence(sequence)

    // Relative lock times are supported by comparing the passed
    // in operand to the sequence number of the input.
    let txSequence = Int64(context.tx.ins[context.inIdx].sequence.sequenceValue)

    // Fail if the transaction's version number is not set high
    // enough to trigger BIP 68 rules.
    if context.tx.version == .v1 { throw ScriptError.invalidScript }

    // Sequence numbers with their most significant bit set are not
    // consensus constrained. Testing that the transaction's sequence
    // number do not have this bit set prevents using this property
    // to get around a CHECKSEQUENCEVERIFY check.
    if txSequence & sequenceLockTimeDisableFlag != 0 { throw ScriptError.invalidScript }

    // Mask off any bits that do not have consensus-enforced meaning
    // before doing the integer comparisons
    let lockTimeMask = sequenceLockTimeTypeFlag | sequenceLockTimeMask
    let txSequenceMasked = txSequence & lockTimeMask
    let sequenceMasked = sequence & lockTimeMask

    // There are two kinds of nSequence: lock-by-blockheight
    // and lock-by-blocktime, distinguished by whether
    // nSequenceMasked < CTxIn::SEQUENCE_LOCKTIME_TYPE_FLAG.
    //
    // We want to compare apples to apples, so fail the script
    // unless the type of nSequenceMasked being tested is the same as
    // the nSequenceMasked in the transaction.
    if !(
        (txSequenceMasked < sequenceLockTimeTypeFlag && sequenceMasked < sequenceLockTimeTypeFlag) ||
        (txSequenceMasked >= sequenceLockTimeTypeFlag && sequenceMasked >= sequenceLockTimeTypeFlag)
    ) { throw ScriptError.invalidScript }

    // Now that we know we're comparing apples-to-apples, the
    // comparison is a simple numeric one.
    if (sequenceMasked > txSequenceMasked) { throw ScriptError.invalidScript }
}
