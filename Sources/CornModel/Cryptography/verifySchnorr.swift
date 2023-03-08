import Foundation
import ECHelper

public func verifySchnorr(sig: Data, msg: Data, pubKey: Data) -> Bool {
    let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let sigPtr = sig.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let pubKeyPtr = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySchnorr(msgPtr, sigPtr, pubKeyPtr) != 0)
}
