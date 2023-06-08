import Foundation
import ECCHelper

func validatePubKey(_ pubKey: Data) -> Bool {
    let pubKeyPtr = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return validatePubKey(pubKeyPtr) != 0
}
