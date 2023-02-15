import Foundation

extension String {

    var varLengthSize: Int {
        UInt64(count / 2).varIntSize + count / 2
    }

    var varLengthData: Data {
        let contentLenData = Data(varInt: UInt64(count / 2))
        let contentData = Data(hex: self)
        return contentLenData + contentData
    }
    
    init(varLengthData: Data) {
        var data = varLengthData
        let contentLen = data.varInt
        data = data.dropFirst(contentLen.varIntSize)
        let contentData = data[..<(data.startIndex + Int(contentLen))]
        self = contentData.hex
    }
}
