import Foundation
import ECCHelper

func verifyECDSA(sig: Data, msg: Data, pubKey: Data) -> Bool {
    let sigPtr = sig.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let pubKeyPtr = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifyECDSA(sigPtr, sig.count, msgPtr, pubKeyPtr, pubKey.count) != 0)
}
