import Foundation
import ECHelper

public func verifySchnorr(signature: Data, message: Data, pubKey: Data) -> Bool {
    let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let pubKeyPointer = pubKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verifySchnorr(messagePointer, signaturePointer, pubKeyPointer) != 0)
}
