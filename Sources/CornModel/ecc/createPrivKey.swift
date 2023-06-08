import Foundation
import ECCHelper

public func createPrivKey() -> Data {
    let privKey: [UInt8] = .init(unsafeUninitializedCapacity: 32) { buf, len in
        let successOrError = createPrivKey(getRandBytesExtern(_:_:), buf.baseAddress, &len)
        precondition(len == 32, "Key must be 32 bytes long.")
        precondition(successOrError == 1, "Computation of internal key failed.")
    }
    return Data(privKey)
}
