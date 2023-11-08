import Foundation
import ECCHelper

public func createSecretKey() -> Data {
    let secretKey: [UInt8] = .init(unsafeUninitializedCapacity: 32) { buf, len in
        let successOrError = createSecretKey(getRandBytesExtern(_:_:), buf.baseAddress, &len)
        precondition(len == 32, "Key must be 32 bytes long.")
        precondition(successOrError == 1, "Computation of internal key failed.")
    }
    return Data(secretKey)
}
