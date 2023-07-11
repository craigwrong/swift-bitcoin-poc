import Foundation

public extension Transaction.Input { struct Witness: Equatable {

    private(set) var elements: [Data]
    
    public init(_ elements: [Data]) {
        self.elements = elements
    }
    
    init(_ data: Data) {
        var data = data
        let witnessLen = data.varInt
        data = data.dropFirst(witnessLen.varIntSize)
        elements = [Data]()
        for _ in 0 ..< witnessLen {
            let element = Data(varLenData: data)
            elements.append(element)
            data = data.dropFirst(element.varLenSize)
        }
    }
    
    var data: Data {
        var ret = Data()
        ret += Data(varInt: UInt64(elements.count))
        ret += elements.reduce(Data()) { $0 + $1.varLenData }
        return ret
    }
    
    var dataCount: Int {
        UInt64(elements.count).varIntSize + elements.varLenSize
    }
    
    var taprootAnnex: Data? {
        // If there are at least two witness elements, and the first byte of the last element is 0x50, this last element is called annex a
        if elements.count > 1, let maybeAnnex = elements.last, let firstElem = maybeAnnex.first, firstElem == 0x50 {
            return maybeAnnex
        } else {
            return .none
        }
    }
} }
