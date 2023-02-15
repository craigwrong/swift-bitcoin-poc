import Foundation
import ECHelper

public func verifyECDSA(signature: Data, message: Data, privateKey privateKeyString: String) -> Bool {
    var messagePointer: UnsafePointer<UInt8>?
    message.withUnsafeBytes { (unsafeBytes) in
        messagePointer = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
    }
    
    let privateKey = Data(hex: privateKeyString)
    var privateKeyPointer: UnsafePointer<UInt8>?
    privateKey.withUnsafeBytes { (unsafeBytes) in
        privateKeyPointer = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
    }

    let signaturePointer = signature.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    return (verify(privateKeyPointer, messagePointer, signaturePointer, signature.count) != 0)
}

public func signECDSA(message: Data, privateKey privateKeyString: String, grind: Bool = true) -> String {
    let messagePointer = message.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    
    let privateKey = Data(hex: privateKeyString)
    var privateKeyPointer: UnsafePointer<UInt8>?
    privateKey.withUnsafeBytes { (unsafeBytes) in
        privateKeyPointer = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
    }
    return String(cString: sign(privateKeyPointer, messagePointer, grind ? 1 : 0))
}

public func signSchnorr(message: Data, privateKey privateKeyString: String) -> String {
    var messagePointer: UnsafePointer<UInt8>?
    message.withUnsafeBytes { (unsafeBytes) in
        messagePointer = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
    }
    
    let privateKey = Data(hex: privateKeyString)
    var privateKeyPointer: UnsafePointer<UInt8>?
    privateKey.withUnsafeBytes { (unsafeBytes) in
        privateKeyPointer = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
    }
    return String(cString: signSchnorr(privateKeyPointer, messagePointer))
}
