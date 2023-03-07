import Foundation

public extension Script {
    enum Op: Equatable {
        case zero, pushBytes(Data), pushData1(Data), pushData2(Data), pushData4(Data), oneNegate, reserved, constant(UInt8), noOp, verify, `return`, drop, dup, equal, equalVerify, ripemd160, sha256, hash160, hash256, codeSeparator, checkSig, checkSigVerify, checkMultiSig, checkMultiSigVerify
    }
}

extension Script.Op {
    
    var memSize: Int {
        let additionalSize: Int
        switch(self) {
        case .pushBytes(let pushData):
            additionalSize = pushData.count
        case .pushData1(let pushData):
            additionalSize = MemoryLayout<UInt8>.size + pushData.count
        case .pushData2(let pushData):
            additionalSize = MemoryLayout<UInt16>.size + pushData.count
        case .pushData4(let pushData):
            additionalSize = MemoryLayout<UInt32>.size + pushData.count
        default:
            additionalSize = 0
        }
        return MemoryLayout<UInt8>.size + additionalSize
    }
    
    var opCode: UInt8 {
        switch(self) {
        case .zero:
            return 0x00
        case .pushBytes(let data):
            return UInt8(data.count)
        case .pushData1(_):
            return 0x4c
        case .pushData2(_):
            return 0x4d
        case .pushData4(_):
            return 0x4e
        case .oneNegate:
            return 0x4f
        case .reserved:
            return 0x50
        case .constant(let k):
            precondition(k > 0 && k < 17)
            return 0x50 + k
        case .noOp:
            return 0x61
        case .verify:
            return 0x69
        case .return:
            return 0x6a
        case .drop:
            return 0x75
        case .dup:
            return 0x76
        case .equal:
            return 0x87
        case .equalVerify:
            return 0x88
        case .ripemd160:
            return 0xa6
        case .sha256:
            return 0xa8
        case .hash160:
            return 0xa9
        case .hash256:
            return 0xaa
        case .codeSeparator:
            return 0xab
        case .checkSig:
            return 0xac
        case .checkSigVerify:
            return 0xad
        case .checkMultiSig:
            return 0xae
        case .checkMultiSigVerify:
            return 0xaf
        }
    }
    
    var keyword: String? {
        switch(self) {
        case .zero:
            return "OP_0"
        case .pushBytes(_):
            return .none
        case .pushData1(_):
            return "OP_PUSHDATA1"
        case .pushData2(_):
            return "OP_PUSHDATA2"
        case .pushData4(_):
            return "OP_PUSHDATA4"
        case .oneNegate:
            return "OP_1NEGATE"
        case .reserved:
            return "OP_RESERVED"
        case .constant(let k):
            precondition(k > 0 && k < 17)
            return "OP_\(k)"
        case .noOp:
            return "OP_NOP"
        case .verify:
            return "OP_VERIFY"
        case .return:
            return "OP_RETURN"
        case .drop:
            return "OP_DROP"
        case .dup:
            return "OP_DUP"
        case .equal:
            return "OP_EQUAL"
        case .equalVerify:
            return "OP_EQUALVERIFY"
        case .ripemd160:
            return "OP_RIPEMD160"
        case .sha256:
            return "OP_SHA256"
        case .hash160:
            return "OP_HASH160"
        case .hash256:
            return "OP_HASH256"
        case .codeSeparator:
            return "OP_CODESEPARATOR"
        case .checkSig:
            return "OP_CHECKSIG"
        case .checkSigVerify:
            return "OP_CHECKSIGVERIFY"
        case .checkMultiSig:
            return "OP_CHECKMULTISIG"
        case .checkMultiSigVerify:
            return "OP_CHECKMULTISIGVERIFY"
        }
    }
    
    func execute(stack: inout [Data], transaction: Tx, prevOuts: [Tx.Out], inputIndex: Int) -> Bool {
        switch(self) {
        
        // Operations that don't consume any parameters from the stack
        case .zero:
            return opConstant(value: 0, stack: &stack)
        case .pushBytes(let data), .pushData1(let data), .pushData2(let data), .pushData4(let data):
            return opPushData(data: data, stack: &stack)
        case .constant(let k):
            precondition(k > 0 && k < 17)
            return opConstant(value: Int8(k), stack: &stack)
        case .oneNegate:
            return opConstant(value: -1, stack: &stack)
        case .reserved:
            return opReserved()
        case .noOp:
            return opNoOp()
        case .return:
            return opReturn()


        // Unary operations
        case .verify, .drop, .dup, .ripemd160, .sha256, .hash160, .hash256:
            guard let first = try? getUnaryParam(&stack) else {
                return false
            }
            switch(self) {
            case .verify:
                return opVerify(first, stack: &stack)
            case .drop:
                return opDrop(first)
            case .dup:
                return opDup(first, stack: &stack)
            case .ripemd160:
                return opRIPEMD160(first, stack: &stack)
            case .sha256:
                return opSHA256(first, stack: &stack)
            case .hash160:
                return opHash160(first, stack: &stack)
            case .hash256:
                return opHash256(first, stack: &stack)
            default:
                fatalError()
            }

        // Binary operations
        case .equal, .equalVerify, .checkSig, .checkMultiSigVerify:
            guard let (first, second) = try? getBinaryParams(&stack) else {
                return false
            }
            switch(self) {
            case .equal:
                return opEqual(first, second, stack: &stack)
            case .equalVerify:
                return opEqualVerify(first, second, stack: &stack)
            case .checkSig:
                return opCheckSig(first, second, stack: &stack, transaction: transaction, prevOuts: prevOuts, inputIndex: inputIndex)
            case .checkSigVerify:
                return opCheckSigVerify(first, second, stack: &stack, transaction: transaction, prevOuts: prevOuts, inputIndex: inputIndex)
            default:
                fatalError()
            }
        default:
            break
        }
        return true
    }
}

public extension Script.Op {
    
    var asm: String {
        if case .pushBytes(let data) = self {
            return data.hex
        }
        guard let keyword else {
            fatalError()
        }
        switch(self) {
        case .zero:
            return "0"
        case .pushData1(let pushData):
            return "\(keyword) \(pushData.hex)"
        case .pushData2(let pushData):
            return "\(keyword) \(pushData.hex)"
        case .pushData4(let pushData):
            return "\(keyword) \(pushData.hex)"
        default:
            return keyword
        }
    }
    
    var data: Data {
        let opCodeData = withUnsafeBytes(of: opCode) { Data($0) }
        let lengthData: Data
        switch(self) {
        case .pushData1(let pushData):
            lengthData = withUnsafeBytes(of: UInt8(pushData.count)) { Data($0) }
        case .pushData2(let pushData):
            lengthData = withUnsafeBytes(of: UInt16(pushData.count)) { Data($0) }
        case .pushData4(let pushData):
            lengthData = withUnsafeBytes(of: UInt32(pushData.count)) { Data($0) }
        default:
            lengthData = Data()
        }
        let rawData: Data
        switch(self) {
        case .pushBytes(let data), .pushData1(let data), .pushData2(let data), .pushData4(let data):
            rawData = data
        default:
            rawData = Data()
        }
        return opCodeData + lengthData + rawData
    }
    
    static func fromData(_ data: Data) -> Self {
        var data = data
        let opCode = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: opCode))
        switch(opCode) {
        case Self.zero.opCode:
            return .zero
        case 0x01 ... 0x4b:
            let pushData = Data(data[data.startIndex ..< data.startIndex + Int(opCode)])
            return .pushBytes(pushData)
        case 0x4c ... 0x4e:
            let pushDataLengthInt: Int
            if opCode == 0x4c {
                let pushDataLength = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataLength))
                pushDataLengthInt = Int(pushDataLength)
            } else if opCode == 0x4d {
                let pushDataLength = data.withUnsafeBytes {  $0.load(as: UInt16.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataLength))
                pushDataLengthInt = Int(pushDataLength)
            } else if opCode == 0x4e {
                let pushDataLength = data.withUnsafeBytes {  $0.load(as: UInt32.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataLength))
                pushDataLengthInt = Int(pushDataLength)
            } else {
                fatalError() // We should never arrive here.
            }
            let pushData = Data(data[data.startIndex ..< data.startIndex + pushDataLengthInt])
            if opCode == 0x4c {
                return .pushData1(pushData)
            } else if opCode == 0x4d {
                return .pushData2(pushData)
            }
            return .pushData4(pushData)
        case Self.oneNegate.opCode:
            return .oneNegate
        case Self.reserved.opCode:
            return .reserved
        case Self.constant(1).opCode ... Self.constant(16).opCode:
            return .constant(opCode - 0x50)
        case Self.noOp.opCode:
            return .noOp
        case Self.verify.opCode:
            return .verify
        case Self.return.opCode:
            return .return
        case Self.drop.opCode:
            return .drop
        case Self.dup.opCode:
            return .dup
        case Self.equal.opCode:
            return .equal
        case Self.equalVerify.opCode:
            return .equalVerify
        case Self.ripemd160.opCode:
            return .ripemd160
        case Self.sha256.opCode:
            return .sha256
        case Self.hash160.opCode:
            return .hash160
        case Self.hash256.opCode:
            return .hash256
        case Self.codeSeparator.opCode:
            return .codeSeparator
        case Self.checkSig.opCode:
            return .checkSig
        case Self.checkSigVerify.opCode:
            return .checkSigVerify
        case Self.checkMultiSig.opCode:
            return .checkMultiSig
        case Self.checkMultiSigVerify.opCode:
            return .checkMultiSigVerify
        default:
            fatalError("Unknown operation code.")
        }
    }
}

enum ScriptError: Error {
    case invalidScript
}

func getUnaryParam(_ stack: inout [Data]) throws -> Data {
    guard stack.count > 0 else {
        throw ScriptError.invalidScript
    }
    return stack.removeLast()
}

func getBinaryParams(_ stack: inout [Data]) throws -> (Data, Data) {
    guard stack.count > 1 else {
        throw ScriptError.invalidScript
    }
    let second = stack.removeLast()
    let first = stack.removeLast()
    return (first, second)
}
