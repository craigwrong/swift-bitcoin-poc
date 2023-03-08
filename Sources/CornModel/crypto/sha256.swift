import Foundation
import CryptoKit

public func sha256(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}
