import Foundation

extension Transaction.Input { public struct Outpoint: Equatable {
        
    public var transaction: String
    public var output: Int

    public init(transaction: String, output: Int) {
        self.transaction = transaction
        self.output = output
    }
    
    init(_ data: Data) {
        var offset = data.startIndex
        let transactionData = Data(data[offset ..< offset + Transaction.identifierDataCount].reversed())
        let transaction = transactionData.hex
        offset += Transaction.identifierDataCount
        let outputData = data[offset ..< offset + MemoryLayout<UInt32>.size]
        let output = Int(outputData.withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        })
        self.init(transaction: transaction, output: output)
    }
    
    static var dataCount: Int {
        Transaction.identifierDataCount + MemoryLayout<UInt32>.size
    }

    var data: Data {
        var ret = Data()
        ret += Data(hex: transaction).reversed()
        ret += withUnsafeBytes(of: UInt32(output)) { Data($0) }
        return ret
    }
} }
