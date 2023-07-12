import Foundation
import ECCHelper

func signECDSA(message: Data, secretKey: Data, grind: Bool = true) -> Data {
   let msgPtr = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let secretKeyPtr = secretKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let sig: [u_char] = .init(unsafeUninitializedCapacity: 74) { buf, len in
      signECDSA(buf.baseAddress, &len, msgPtr, secretKeyPtr, grind ? 1 : 0)
   }
   return Data(sig)
}
