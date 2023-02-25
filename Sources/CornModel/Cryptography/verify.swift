import Foundation
import ECHelper

public func verify(signature: Data, message: Data, privateKey: Data) -> Bool {
   let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   return (verifySignature(signaturePointer, signature.count, messagePointer, privateKeyPointer) != 0)
}
