import Foundation
import ECHelper

public func sign(message: Data, privateKey: Data, grind: Bool = true) -> Data {
   let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privateKeyPointer = privateKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let signature: [u_char] = .init(unsafeUninitializedCapacity: 74) { buffer, initializedCount in
      sign(buffer.baseAddress, &initializedCount, messagePointer, privateKeyPointer, grind ? 1 : 0)
   }
   return Data(signature)
}
