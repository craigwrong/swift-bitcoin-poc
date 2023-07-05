import Foundation

struct ScriptContext {
    let transaction: Transaction
    let inputIndex: Int
    let previousOutputs: [Transaction.Output]
    let script: Script
    private(set) var succeedUnconditionally = false
    let tapLeafHash: Data?
    let keyVersion: UInt8? = 0
    var operationIndex: Int = 0
    var altStack: [Data] = []
    
    var pendingIfOperations = [Bool?]()
    var pendingElseOperations = 0

    var previousOutput: Transaction.Output {
        previousOutputs[inputIndex]
    }

    var evaluateBranch: Bool {
        guard let lastEvaluatedIfResult = pendingIfOperations.last(where: { $0 != .none }), let lastEvaluatedIfResult else {
            return true
        }
        return lastEvaluatedIfResult
    }
    
    mutating func setSucceedUnconditionally() {
        if !succeedUnconditionally {
            succeedUnconditionally.toggle()
        }
    }
}
