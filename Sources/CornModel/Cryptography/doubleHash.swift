import Foundation
import CryptoKit

public func doubleHash(_ data: Data) -> Data {
    let digest = SHA256.hash(data: singleHash(data))
    return Data(digest)
}
