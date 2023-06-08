extension UInt64 {
    
    var varIntSize: Int {
        switch self {
        case 0 ..< 0xfd:
            return 1
        case 0xfd ... UInt64(UInt16.max):
            return 1 + MemoryLayout<UInt16>.size
        case UInt64(UInt16.max) + 1 ... UInt64(UInt32.max):
            return 1 + MemoryLayout<UInt32>.size
        case UInt64(UInt32.max) + 1 ... UInt64.max:
            return 1 + MemoryLayout<UInt64>.size
        default:
            fatalError()
        }
    }
}
