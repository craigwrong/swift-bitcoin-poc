import Foundation
import ECHelper

public func signSchnorr(msg: Data, privKey: Data, merkleRoot: Data?, forceTweak: Bool = false, aux: Data?) -> Data {
    let msgPtr = msg.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let privKeyPtr = privKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let merkleRootPtr = merkleRoot?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let auxPtr = aux?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    
    let sig: [UInt8] = .init(unsafeUninitializedCapacity: 64) { buf, len in
        let successOrError = signSchnorr(computeTapTweakHashWrapped(_:_:_:), buf.baseAddress, &len, msgPtr, merkleRootPtr, forceTweak ? 1 : 0, auxPtr, privKeyPtr)
        precondition(len == 64, "Signature must be 64 bytes long.")
        precondition(successOrError == 1, "Signing with Schnorr failed.")
    }
    return Data(sig)
}
