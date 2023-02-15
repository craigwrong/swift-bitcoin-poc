import Foundation

public extension Tx {
    struct Witness: Equatable {
        var stack: [String]
    }
}

extension Tx.Witness {
    
    var memSize: Int {
        UInt64(stack.count).varIntSize + stack.varLengthSize
    }
}

public extension Tx.Witness {

    var data: Data {
        let stackCountData = Data(varInt: UInt64(stack.count))
        let stackData = stack.reduce(Data()) { $0 + $1.varLengthData }
        return stackCountData + stackData
    }
    
    init(_ data: Data) {
        var data = data
        let stackCount = data.varInt
        data = data.dropFirst(stackCount.varIntSize)
        
        var stack = [String]()
        for _ in 0 ..< stackCount {
            let stackElement = String(varLengthData: data)
            stack.append(stackElement)
            data = data.dropFirst(stackElement.varLengthSize)
        }
        self.init(stack: stack)
    }
}
