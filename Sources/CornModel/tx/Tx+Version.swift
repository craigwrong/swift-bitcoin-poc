import Foundation

extension Tx {
    
    /// The version of this bitcoin transaction. Either v1 or v2.
    public enum Version: Equatable {
        case v1, v2, unknown(UInt32)
        
        init(_ data: Data) {
            let uInt32 = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            self = uInt32 == 1 ? .v1 : uInt32 == 2 ? .v2 : .unknown(uInt32)
        }
        
        var uInt32: UInt32 {
            switch(self) {
                case .v1:
                    return UInt32(1)
                case .v2:
                    return UInt32(2)
                case let .unknown(value):
                    return value
            }
        }
        
        var data: Data {
            withUnsafeBytes(of: uInt32) { Data($0) }
        }
        
        var dataLen: Int {
            MemoryLayout.size(ofValue: uInt32)
        }
    }
}
