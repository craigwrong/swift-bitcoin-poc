import Foundation

struct ExecutionContext {
    let transaction: Transaction
    let inputIndex: Int
    let previousOutputs: [Transaction.Output]
    let script: Script
    let version: Script.Version
    let tapLeafHash: Data?
    let keyVersion: UInt8? = 0
    var operationIndex: Int = 0
    var altStack: [Data] = []
    
    // If else support
    var pendingIfs = 0
    var pendingElses = 0
    var evalElse = false

    var previousOutput: Transaction.Output {
        previousOutputs[inputIndex]
    }
}
