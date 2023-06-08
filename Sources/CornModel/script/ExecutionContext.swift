import Foundation

struct ExecutionContext {
    let tx: Tx
    let inIdx: Int
    let prevOuts: [Tx.Out]
    let script: [Op]
    let version: ScriptVersion
    let tapLeafHash: Data?
    let keyVersion: UInt8? = 0
    var opIdx: Int = 0

    var prevOut: Tx.Out {
        prevOuts[inIdx]
    }
}
