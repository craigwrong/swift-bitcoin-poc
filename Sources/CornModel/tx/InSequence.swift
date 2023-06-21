import Foundation

public extension Tx.In {
    struct Sequence: Equatable {
        public static let initial = Self(0)
        public static let secondFinal = Self(0xfffffffe)
        public static let final = Self(0xffffffff)
        public static let locktimeDisabled  = Self(locktimeDisableFlag)
        public static let zeroLocktimeBlocks = initial
        public static let maxLocktimeBlocks = Self(locktimeMask)
        public static let zeroLocktimeSeconds = Self(locktimeClockFlag)
        public static let maxLocktimeSeconds = Self(locktimeClockFlag | locktimeMask)

        public init?(locktimeBlocks blocks: Int) {
            guard blocks >= Self.zeroLocktimeBlocks.sequenceValue && blocks <= Self.locktimeMask else {
                return nil
            }
            self.init(blocks)
        }
        
        public init?(locktimeSeconds seconds: Int) {
            guard seconds >= Self.initial.sequenceValue && seconds <= Self.maxSeconds else {
                return nil
            }
            self.init(seconds >> Self.granularity)
        }
        
        public var isLocktimeDisabled: Bool {
            sequenceValue & Self.locktimeDisableFlag != 0
        }
        
        public var locktimeBlocks: Int? {
            guard !isLocktimeDisabled && (sequenceValue & Self.locktimeClockFlag == 0) else {
                return nil
            }
            return sequenceValue & Self.locktimeMask
        }
        
        public var locktimeSeconds: Int? {
            guard !isLocktimeDisabled && (sequenceValue & Self.locktimeClockFlag != 0) else {
                return nil
            }
            return (sequenceValue & Self.locktimeMask) << Self.granularity
        }

        static var dataCount: Int {
            MemoryLayout<UInt32>.size
        }

        init?(_ data: Data) {
            guard data.count >= Self.dataCount else {
                return nil
            }
            let rawValue = data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
            self.init(rawValue)
        }
        
        init(_ rawValue: UInt32) {
            self.init(Int(rawValue))
        }
        
        var data: Data {
            withUnsafeBytes(of: rawValue) { Data($0) }
        }

        var rawValue: UInt32 {
            UInt32(sequenceValue)
        }

        private static let locktimeMask = 0xffff
        private static let locktimeClockFlag = 0x400000 // 1 << 22
        private static let locktimeDisableFlag = 0x80000000 // 1 << 31
        private static let granularity = 9 // Base 2 exponent: pow(2, 9) = 512 seconds
        private static let maxSeconds = locktimeMask << granularity
        
        private init(_ sequenceValue: Int) {
            self.sequenceValue = sequenceValue
        }

        private let sequenceValue: Int
    }
}
