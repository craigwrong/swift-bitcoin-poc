import Foundation

extension Data {

    var varLengthSize: Int {
        UInt64(count).varIntSize + count
    }

    var varLengthData: Data {
        let contentLenData = Data(varInt: UInt64(count))
        return contentLenData + self
    }
    
    init(varLengthData: Data) {
        var data = varLengthData
        let contentLen = data.varInt
        data = data.dropFirst(contentLen.varIntSize)
        self = data[..<(data.startIndex + Int(contentLen))]
    }
}
