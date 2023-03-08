import Foundation
import ECHelper

public func verifyWithPubKey(sig: Data, msg: Data, pubKey: Data) -> Bool {
    let sigPtr = sig.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let pubKeyPtr = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySignatureWithPubKey(sigPtr, sig.count, msgPtr, pubKeyPtr, pubKey.count) != 0)
}

public func verifyWithSecretKey(sig: Data, msg: Data, secretKey: Data) -> Bool {
    let sigPtr = sig.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let secretKeyPtr = secretKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySignatureWithSecretKey(sigPtr, sig.count, msgPtr, secretKeyPtr) != 0)
}
