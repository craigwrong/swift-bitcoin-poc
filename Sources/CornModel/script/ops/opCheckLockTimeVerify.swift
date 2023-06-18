import Foundation

/// [BIP65](https://github.com/bitcoin/bips/blob/master/bip-0065.mediawiki)
func opCheckLockTimeVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    // Note that elsewhere numeric opcodes are limited to
    // operands in the range -2**31+1 to 2**31-1, however it is
    // legal for opcodes to produce results exceeding that
    // range. This limitation is implemented by CScriptNum's
    // default 4-byte limit.
    //
    // If we kept to that limit we'd have a year 2038 problem,
    // even though the nLockTime field in transactions
    // themselves is uint32 which only becomes meaningless
    // after the year 2106.
    //
    // Thus as a special case we tell CScriptNum to accept up
    // to 5-byte bignums, which are good until 2**32-1, the
    // same limit as the nLockTime field itself.
    let first = try getUnaryParam(&stack)
    guard first.count < 6, let lockTime = first.asInt64, lockTime >= 0 else {
        throw ScriptError.invalidScript
    }

    // In the rare event that the argument may be < 0 due to
    // some arithmetic being done first, you can always use
    // 0 MAX CHECKLOCKTIMEVERIFY.
    guard lockTime >= 0 else { throw ScriptError.invalidScript }

    // There are two types of nLockTime: lock-by-blockheight
    // and lock-by-blocktime, distinguished by whether
    // nLockTime < LOCKTIME_THRESHOLD.
    //
    // We want to compare apples to apples, so fail the script
    // unless the type of nLockTime being tested is the same as
    // the nLockTime in the transaction.
    if !(
          (context.tx.lockTime <  Tx.lockTimeThreshold && lockTime <  Tx.lockTimeThreshold) ||
          (context.tx.lockTime >= Tx.lockTimeThreshold && lockTime >= Tx.lockTimeThreshold)
         ) {
        throw ScriptError.invalidScript
    }

    // Now that we know we're comparing apples-to-apples, the
    // comparison is a simple numeric one.
    if lockTime > Int64(context.tx.lockTime) {
        throw ScriptError.invalidScript
    }

    // Finally the nLockTime feature can be disabled and thus
    // CHECKLOCKTIMEVERIFY bypassed if every txin has been
    // finalized by setting nSequence to maxint. The
    // transaction would be allowed into the blockchain, making
    // the opcode ineffective.
    //
    // Testing if this vin is not final is sufficient to
    // prevent this condition. Alternatively we could test all
    // inputs, but testing just this input minimizes the data
    // required to prove correct CHECKLOCKTIMEVERIFY execution.
    if context.tx.ins[context.inIdx].sequence.isFinal {
        throw ScriptError.invalidScript
    }
}
