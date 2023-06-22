import Foundation

extension Transaction { public struct Locktime: Equatable {

    public static let disabled = Self(0)
    public static let maxBlock = Self(minClock.locktimeValue - 1)
    public static let minClock = Self(500_000_000)
    public static let maxClock = Self(Int(UInt32.max))

    public init?(blockHeight: Int) {
        guard blockHeight >= Self.disabled.locktimeValue && blockHeight <= Self.maxBlock.locktimeValue else {
            return nil
        }
        self.init(blockHeight)
    }
    
    public init?(secondsSince1970: Int) {
        guard secondsSince1970 >= Self.minClock.locktimeValue && secondsSince1970 <= Self.maxClock.locktimeValue else {
            return nil
        }
        self.init(secondsSince1970)
    }
    
    public var isDisabled: Bool {
        locktimeValue == Self.disabled.locktimeValue
    }
    
    public var blockHeight: Int? {
        guard locktimeValue <= Self.maxBlock.locktimeValue else {
            return nil
        }
        return locktimeValue
    }
    
    public var secondsSince1970: Int? {
        guard locktimeValue >= Self.minClock.locktimeValue else {
            return nil
        }
        return locktimeValue
    }

    static var dataCount: Int {
        MemoryLayout<UInt32>.size
    }

    init?(_ data: Data) {
        guard data.count >= Self.dataCount else {
            return nil
        }
        let value32 = data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        self.init(value32)
    }
    
    init(_ rawValue: UInt32) {
        self.init(Int(rawValue))
    }
    
    var data: Data {
        withUnsafeBytes(of: rawValue) { Data($0) }
    }

    var rawValue: UInt32 {
        UInt32(locktimeValue)
    }

    private init(_ locktimeValue: Int) {
        self.locktimeValue = locktimeValue
    }
    
    private let locktimeValue: Int
} }
