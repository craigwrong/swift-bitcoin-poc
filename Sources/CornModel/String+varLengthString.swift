import Foundation

extension Data {

    /// Memory size as variable length array (array prefixed with its element count as compact integer).
    var varLenSize: Int {
        UInt64(count).varIntSize + count
    }

    var varLenData: Data {
        let contentLenData = Data(varInt: UInt64(count))
        return contentLenData + self
    }
    
    init(varLenData: Data) {
        var data = varLenData
        let contentLen = data.varInt
        data = data.dropFirst(contentLen.varIntSize)
        self = data[..<(data.startIndex + Int(contentLen))]
    }
}
