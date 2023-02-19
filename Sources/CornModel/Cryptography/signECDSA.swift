import Foundation
import ECHelper

public func verify(signature: Data, message: Data, privateKey: Data) -> Bool {
   let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   return (verify(signaturePointer, signature.count, messagePointer, privateKeyPointer) != 0)
}

public func sign(message: Data, privateKey: Data, grind: Bool = true) -> Data {
   let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let signature: [u_char] = .init(unsafeUninitializedCapacity: 74) { buffer, initializedCount in
      cSign(buffer.baseAddress, &initializedCount, messagePointer, privateKeyPointer, grind ? 1 : 0)
   }
   return Data(signature)
}

public func signSchnorr(message: Data, privateKey: Data) -> String {
   let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   return String(cString: signSchnorr(privateKeyPointer, messagePointer))
}
