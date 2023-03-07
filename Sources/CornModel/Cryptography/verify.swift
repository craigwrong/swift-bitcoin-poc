import Foundation
import ECHelper

public func verifyWithPubKey(signature: Data, message: Data, pubKey: Data) -> Bool {
    let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let pubKeyPointer = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySignatureWithPubKey(signaturePointer, signature.count, messagePointer, pubKeyPointer, pubKey.count) != 0)
}

public func verifyWithSecretKey(signature: Data, message: Data, privateKey: Data) -> Bool {
    let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySignatureWithSecretKey(signaturePointer, signature.count, messagePointer, privateKeyPointer) != 0)
}
