import Foundation

public extension Tx {
    struct Witness: Equatable {
        var stack: [Data]
    }
}

extension Tx.Witness {
    
    var memSize: Int {
        UInt64(stack.count).varIntSize + stack.varLenSize
    }
}

public extension Tx.Witness {

    var data: Data {
        let stackCountData = Data(varInt: UInt64(stack.count))
        let stackData = stack.reduce(Data()) { $0 + $1.varLenData }
        return stackCountData + stackData
    }
    
    init(_ data: Data) {
        var data = data
        let stackCount = data.varInt
        data = data.dropFirst(stackCount.varIntSize)
        
        var stack = [Data]()
        for _ in 0 ..< stackCount {
            let stackElement = Data(varLenData: data)
            stack.append(stackElement)
            data = data.dropFirst(stackElement.varLenSize)
        }
        self.init(stack: stack)
    }
}
