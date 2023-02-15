import Foundation
import CryptoKit

public func singleHash(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}
