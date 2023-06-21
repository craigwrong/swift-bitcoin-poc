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

    let locktime = Tx.Locktime(UInt32(lockTime64))

    if let blockHeight = locktime.blockHeight, let txBlockHeight = context.tx.locktime.blockHeight {
        if blockHeight > txBlockHeight {
            throw ScriptError.invalidScript
        }
    } else if let seconds = locktime.secondsSince1970, let txSeconds = context.tx.locktime.secondsSince1970 {
        if seconds > txSeconds {
            throw ScriptError.invalidScript
        }
    } else {
        throw ScriptError.invalidScript
    }
    
    if context.tx.ins[context.inIdx].sequence == .final { throw ScriptError.invalidScript }
}
