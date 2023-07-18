import Foundation
import CryptoKit

func sha1(_ data: Data) -> Data {
    Data(Insecure.SHA1.hash(data: data))
}
