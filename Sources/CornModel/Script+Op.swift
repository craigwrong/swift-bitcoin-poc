import Foundation

public extension Script {
    enum Op: Equatable {
        case `false`, `true`, pushBytes(Data), pushData1(Data), pushData2(Data), pushData4(Data), oneNegate, zero, one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen, fourteen, fifteen, sixteen, noOp, `return`, codeSeparator, dup, sha256, hash160, hash256, checkSig, checkSigVerify, checkMultiSig, checkMultiSigVerify, equal, equalVerify, verify
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
        case .false:
            return 0x00 // same as .zero
        case .true:
            return 0x51 // Same as .one
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
        case .zero:
            return 0x00
        case .one:
            return 0x51
        case .two:
            return 0x52
        case .three:
            return 0x53
        case .four:
            return 0x54
        case .five:
            return 0x55
        case .six:
            return 0x56
        case .seven:
            return 0x57
        case .eight:
            return 0x58
        case .nine:
            return 0x59
        case .ten:
            return 0x5a
        case .eleven:
            return 0x5b
        case .twelve:
            return 0x5c
        case .thirteen:
            return 0x5d
        case .fourteen:
            return 0x5e
        case .fifteen:
            return 0x5f
        case .sixteen:
            return 0x60
        case .noOp:
            return 0x61
        case .return:
            return 0x6a
        case .codeSeparator:
            return 0xab
        case .dup:
            return 0x76
        case .sha256:
            return 0xa8
        case .hash160:
            return 0xa9
        case .hash256:
            return 0xaa
        case .checkSig:
            return 0xac
        case .checkSigVerify:
            return 0xad
        case .checkMultiSig:
            return 0xae
        case .checkMultiSigVerify:
            return 0xaf
        case .equal:
            return 0x87
        case .equalVerify:
            return 0x88
        case .verify:
            return 0x69
        }
    }
    
    var word: String? {
        switch(self) {
        case .false:
            return "OP_FALSE"
        case .true:
            return "OP_TRUE" // Same as .one
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
        case .zero:
            return "OP_0"
        case .one:
            return "OP_1"
        case .two:
            return "OP_2"
        case .three:
            return "OP_3"
        case .four:
            return "OP_4"
        case .five:
            return "OP_5"
        case .six:
            return "OP_6"
        case .seven:
            return "OP_7"
        case .eight:
            return "OP_8"
        case .nine:
            return "OP_9"
        case .ten:
            return "OP_10"
        case .eleven:
            return "OP_11"
        case .twelve:
            return "OP_12"
        case .thirteen:
            return "OP_13"
        case .fourteen:
            return "OP_14"
        case .fifteen:
            return "OP_15"
        case .sixteen:
            return "OP_16"
        case .noOp:
            return "OP_NOP"
        case .return:
            return "OP_RETURN"
        case .codeSeparator:
            return "OP_CODESEPARATOR"
        case .dup:
            return "OP_DUP"
        case .sha256:
            return "OP_SHA256"
        case .hash160:
            return "OP_HASH160"
        case .hash256:
            return "OP_HASH256"
        case .checkSig:
            return "OP_CHECKSIG"
        case .checkSigVerify:
            return "OP_CHECKSIGVERIFY"
        case .checkMultiSig:
            return "OP_CHECKMULTISIG"
        case .checkMultiSigVerify:
            return "OP_CHECKMULTISIGVERIFY"
        case .equal:
            return "OP_EQUAL"
        case .equalVerify:
            return "OP_EQUALVERIFY"
        case .verify:
            return "OP_VERIFY"
        }
    }
    
}

public extension Script.Op {
    
    var asm: String {
        if case .pushBytes(let data) = self {
            return data.hex
        }
        guard let word else {
            fatalError()
        }
        switch(self) {
        case .zero:
            return "0"
        case .pushData1(let pushData):
            return "\(word) \(pushData.hex)"
        case .pushData2(let pushData):
            return "\(word) \(pushData.hex)"
        case .pushData4(let pushData):
            return "\(word) \(pushData.hex)"
        default:
            return word
        }
    }
    
    var data: Data {
        let opCodeData = withUnsafeBytes(of: opCode) { Data($0) }
        let lengthData: Data
        let rawData: Data
        switch(self) {
        case .pushBytes(let pushData):
            lengthData = Data()
            rawData = pushData
        case .pushData1(let pushData):
            lengthData = withUnsafeBytes(of: UInt8(pushData.count)) { Data($0) }
            rawData = pushData
        case .pushData2(let pushData):
            lengthData = withUnsafeBytes(of: UInt16(pushData.count)) { Data($0) }
            rawData = pushData
        case .pushData4(let pushData):
            lengthData = withUnsafeBytes(of: UInt32(pushData.count)) { Data($0) }
            rawData = pushData
        default:
            lengthData = Data()
            rawData = Data()
            break
        }
        return opCodeData + lengthData + rawData
    }
    
    static func fromData(_ data: Data) -> Self {
        var data = data
        let opCode = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: opCode))
        if (UInt8(0x01)...0x4b).contains(opCode) {
            let pushData = Data(data[data.startIndex ..< data.startIndex + Int(opCode)])
            return .pushBytes(pushData)
        }
        if (UInt8(0x4c)...0x4e).contains(opCode) {
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
            } else if opCode == 0x4e {
                return .pushData4(pushData)
            }
        }
        switch(opCode) {
        case 0x4f:
            return .oneNegate
        case 0x00:
            return .zero
        case 0x51:
            return .one
        case 0x52:
            return .two
        case 0x53:
            return .three
        case 0x54:
            return .four
        case 0x55:
            return .five
        case 0x56:
            return .six
        case 0x57:
            return .seven
        case 0x58:
            return .eight
        case 0x59:
            return .nine
        case 0x5a:
            return .ten
        case 0x5b:
            return .eleven
        case 0x5c:
            return .twelve
        case 0x5d:
            return .thirteen
        case 0x5e:
            return .fourteen
        case 0x5f:
            return .fifteen
        case 0x60:
            return .sixteen
        case 0x61:
            return .noOp
        case 0x6a:
            return .return
        case 0xab:
            return .codeSeparator
        case 0x76:
            return .dup
        case 0xa8:
            return .sha256
        case 0xa9:
            return .hash160
        case 0xaa:
            return .hash256
        case 0xac:
            return .checkSig
        case 0xad:
            return .checkSigVerify
        case 0xae:
            return .checkMultiSig
        case 0xaf:
            return .checkMultiSigVerify
        case 0x87:
            return .equal
        case 0x88:
            return .equalVerify
        case 0x69:
            return .verify
        default:
            fatalError("Unknown operation code.")
        }
    }
}
