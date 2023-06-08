import Foundation
import ECCHelper

func signECDSA(msg: Data, privKey: Data, grind: Bool = true) -> Data {
   let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let privKeyPtr = privKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
   let sig: [u_char] = .init(unsafeUninitializedCapacity: 74) { buf, len in
      signECDSA(buf.baseAddress, &len, msgPtr, privKeyPtr, grind ? 1 : 0)
   }
   return Data(sig)
}
