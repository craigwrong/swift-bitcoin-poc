import Foundation

public extension Tx {
    
    /// The version of this bitcoin transaction. Either v1 or v2.
    enum Version: Int {
        case v1 = 1, v2
        
        init?(_ data: Data) {
            let uInt32 = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            self.init(rawValue: Int(uInt32))
        }
        
        var uInt32: UInt32 {
            UInt32(rawValue)
        }
        
        var data: Data {
            withUnsafeBytes(of: uInt32) { Data($0) }
        }
        
        var dataLen: Int {
            MemoryLayout.size(ofValue: uInt32)
        }
    }
}
