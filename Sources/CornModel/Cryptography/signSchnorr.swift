import Foundation
import ECHelper

public func signSchnorr(message: Data, secretKey: Data, merkleRoot: Data?, forceTweak: Bool = false, aux: Data?) -> Data {
    let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let secretKeyPointer = secretKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let merkleRootPointer = merkleRoot?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let auxPointer = aux?.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    
    let signature: [UInt8] = .init(unsafeUninitializedCapacity: 64) { signatureBuffer, signatureBufferLength in
        let successOrError = signSchnorr(computeTapTweakHashWrapped(_:_:_:), signatureBuffer.baseAddress, &signatureBufferLength, messagePointer, merkleRootPointer, forceTweak ? 1 : 0, auxPointer, secretKeyPointer)
        precondition(signatureBufferLength == 64, "Signature must be 64 bytes long.")
        precondition(successOrError == 1, "Signing with Schnorr failed.")
    }
    return Data(signature)
}
