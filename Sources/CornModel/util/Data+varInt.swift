import Foundation

extension Data {
    
    /// Converts a 64-bit integer into its compact integer representation – i.e. variable length data.
    init(varInt value: UInt64) {
        if value < 0xfd {
            var valueVar = UInt8(value)
            self.init(bytes: &valueVar, count: MemoryLayout.size(ofValue: valueVar))
        } else if value <= UInt16.max {
            self = Data([0xfd]) + Swift.withUnsafeBytes(of: UInt16(value)) { Data($0) }
        } else if value <= UInt32.max {
            self = Data([0xfe]) + Swift.withUnsafeBytes(of: UInt32(value)) { Data($0) }
        } else {
            self = Data([0xff]) + Swift.withUnsafeBytes(of: value) { Data($0) }
        }
    }
    
    /// Parses bytes interpreted as variable length – i.e. compact integer – data into a 64-bit integer.
    var varInt: UInt64 {
        guard let firstByte = first else {
            fatalError("Data is empty.")
        }
        
        let tail = dropFirst()
        
        if firstByte < 0xfd {
            return UInt64(firstByte)
        }
        if firstByte == 0xfd {
            let value = tail.withUnsafeBytes {
                $0.load(as: UInt16.self)
            }
            return UInt64(value)
        }
        if firstByte == 0xfd {
            let value = tail.withUnsafeBytes {
                $0.load(as: UInt32.self)
            }
            return UInt64(value)
        }
        let value = tail.withUnsafeBytes {
            $0.load(as: UInt64.self)
        }
        return value
    }
}
