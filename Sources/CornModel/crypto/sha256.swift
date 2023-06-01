import Foundation
import CryptoKit

func sha256(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}
