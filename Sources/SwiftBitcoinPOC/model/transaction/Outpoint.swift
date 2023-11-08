import Foundation

public struct Outpoint: Equatable {
        
    public var transaction: String
    public var output: Int

    public init(transaction: String, output: Int) {
        self.transaction = transaction
        self.output = output
    }
    
    init(_ data: Data) {
        var offset = data.startIndex
        let transactionData = Data(data[offset ..< offset + Transaction.idSize].reversed())
        let transaction = transactionData.hex
        offset += Transaction.idSize
        let outputData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let output = Int(outputData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        })
        self.init(transaction: transaction, output: output)
    }
    
    static var size: Int {
        Transaction.idSize + MemoryLayout<UInt32>.size
    }

    var data: Data {
        var ret = Data()
        ret += Data(hex: transaction).reversed()
        ret += withUnsafeBytes(of: UInt32(output)) { Data($0) }
        return ret
    }
}
