import Foundation

public extension Tx {
    
    struct Out: Equatable {
        public init(value: UInt64, scriptPubKey: Script) {
            self.value = value
            self.scriptPubKey = scriptPubKey
        }
        
        public var value: UInt64 // Sats
        public var scriptPubKey: Script
    }
}

extension Tx.Out {
    var memSize: Int {
        MemoryLayout.size(ofValue: value) + scriptPubKey.memSize
    }
}

public extension Tx.Out {

    var doubleValue: Double {
        Double(value) / 100_000_000
    }

    var data: Data {
        return valueData + scriptPubKey.data()
    }

    var valueData: Data {
        withUnsafeBytes(of: value) { Data($0) }
    }
    
    init(_ data: Data) {
        let value = data.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
        let data = data.dropFirst(MemoryLayout.size(ofValue: value))
        let scriptPubKey = Script(data)
        self.init(value: value, scriptPubKey: scriptPubKey)
    }
}
