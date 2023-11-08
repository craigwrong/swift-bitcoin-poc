import Foundation

public struct Version: Equatable {
    
    public static let v1 = Self(1)
    public static let v2 = Self(2)

    private let versionValue: Int
    
    init?(futureVersion versionValue: Int) {
        guard versionValue > Self.v2.versionValue, versionValue <= UInt32.max else {
            return nil
        }
        self.init(versionValue)
    }
    
    init?(_ data: Data) {
        guard data.count >= Self.size else {
            return nil
        }
        let rawValue = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        self.init(rawValue)
    }
    
    init(_ rawValue: UInt32) {
        self.init(Int(rawValue))
    }

    private init(_ versionValue: Int) {
        self.versionValue = versionValue
    }
    
    static var size: Int {
        MemoryLayout<UInt32>.size
    }
    
    public var isFuture: Bool {
        versionValue > Self.v2.versionValue
    }

    var data: Data {
        withUnsafeBytes(of: rawValue) { Data($0) }
    }
    
    var rawValue: UInt32 {
        UInt32(versionValue)
    }
    
}
