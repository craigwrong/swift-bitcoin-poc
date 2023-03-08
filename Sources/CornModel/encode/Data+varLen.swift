import Foundation

extension Data {
    
    init(varLenData: Data) {
        var data = varLenData
        let contentLen = data.varInt
        data = data.dropFirst(contentLen.varIntSize)
        self = data[..<(data.startIndex + Int(contentLen))]
    }
    
    var varLenData: Data {
        let contentLenData = Data(varInt: UInt64(count))
        return contentLenData + self
    }
    
    /// Memory size as variable length byte array (array prefixed with its element count as compact integer).
    var varLenSize: Int {
        UInt64(count).varIntSize + count
    }
}
