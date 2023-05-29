import Foundation
import ECCHelper

public func getPubKey(privKey: Data, compress: Bool = true) -> Data {
    let privKeyPtr = privKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    
    let pubKey: [UInt8] = .init(unsafeUninitializedCapacity: PUBKEY_MAX_LEN) { buf, len in
        let successOrError = getPubKey(buf.baseAddress, &len, privKeyPtr, compress ? 1 : 0)
        precondition(len == PUBKEY_MAX_LEN || len == PUBKEY_COMPRESSED_LEN, "Key must be either 65 (uncompressed) or 33 (compressed) bytes long.")
        precondition(successOrError == 1, "Computation of internal key failed.")
    }
    return Data(pubKey)
}
