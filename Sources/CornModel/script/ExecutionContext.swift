import Foundation

struct ExecutionContext {
    let tx: Transaction
    let inIdx: Int
    let prevOuts: [Transaction.Output]
    let script: Script
    let version: Script.Version
    let tapLeafHash: Data?
    let keyVersion: UInt8? = 0
    var opIdx: Int = 0
    var altStack: [Data] = []
    
    // If else support
    var pendingIfs = 0
    var pendingElses = 0
    var evalElse = false

    var prevOut: Transaction.Output {
        prevOuts[inIdx]
    }
}
