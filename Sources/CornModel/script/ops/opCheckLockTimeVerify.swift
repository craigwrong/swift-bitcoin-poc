import Foundation

/// [BIP65](https://github.com/bitcoin/bips/blob/master/bip-0065.mediawiki)
func opCheckLockTimeVerify(_ stack: inout [Data], context: ExecutionContext) throws {
    let first = try getUnaryParam(&stack, keep: true)

    guard
        first.count < 6,
        let lockTime64 = first.asInt64,
        lockTime64 >= 0,
        lockTime64 <= UInt32.max
    else { throw ScriptError.invalidScript }

    let lockTime = UInt32(lockTime64)

    guard
        context.tx.lockTime < Tx.lockTimeThreshold &&
            lockTime < Tx.lockTimeThreshold ||
        (context.tx.lockTime >= Tx.lockTimeThreshold &&
            lockTime >= Tx.lockTimeThreshold)
    else { throw ScriptError.invalidScript }

    if lockTime > context.tx.lockTime { throw ScriptError.invalidScript }

    if context.tx.ins[context.inIdx].sequence.isFinal { throw ScriptError.invalidScript }
}
