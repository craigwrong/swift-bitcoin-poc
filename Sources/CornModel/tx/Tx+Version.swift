import Foundation

extension Tx {
    public struct Version: Equatable {
        public static let v1 = Self(1)
        public static let v2 = Self(2)

        public var isFuture: Bool {
            versionValue > Self.v2.versionValue
        }

        static var dataCount: Int {
            MemoryLayout<UInt32>.size
        }

        init?(futureVersion versionValue: Int) {
            guard versionValue > Self.v2.versionValue, versionValue <= UInt32.max else {
                return nil
            }
            self.init(versionValue)
        }
        
        init?(_ data: Data) {
            guard data.count >= Self.dataCount else {
                return nil
            }
            let rawValue = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            self.init(rawValue)
        }
        
        init(_ rawValue: UInt32) {
            self.init(Int(rawValue))
        }
        
        var data: Data {
            withUnsafeBytes(of: rawValue) { Data($0) }
        }

        var rawValue: UInt32 {
            UInt32(versionValue)
        }
        
        private let versionValue: Int
        
        private init(_ versionValue: Int) {
            self.versionValue = versionValue
        }
    }
}
