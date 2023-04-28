import Foundation
import ECCHelper

public func getInternalKey(privKey: Data) -> Data {
    let privKeyPtr = privKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    
    let internalKey: [UInt8] = .init(unsafeUninitializedCapacity: 32) { buf, len in
        let successOrError = getInternalKey(buf.baseAddress, &len, privKeyPtr)
        precondition(len == 32, "Key must be 32 bytes long.")
        precondition(successOrError == 1, "Computation of internal key failed.")
    }
    return Data(internalKey)
}
