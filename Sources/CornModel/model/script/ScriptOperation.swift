import Foundation

public enum ScriptOperation: Equatable {
    case zero, pushBytes(Data), pushData1(Data), pushData2(Data), pushData4(Data), oneNegate, /* legacy,V0 */ reserved(UInt8), /* V1+ */ success(UInt8), constant(UInt8), noOp, ver, `if`, notIf, verIf, verNotIf, `else`, endIf, verify, `return`, toAltStack, fromAltStack, twoDrop, twoDup, ifDup, drop, dup, swap, equal, equalVerify, negate, add, boolAnd, ripemd160, sha256, hash160, hash256, codeSeparator, checkSig, checkSigVerify, checkMultiSig, checkMultiSigVerify, checkLockTimeVerify, checkSequenceVerify, /* V1+ */ checkSigAdd, undefined
}

extension ScriptOperation {
    var dataCount: Int {
        let additionalSize: Int
        switch(self) {
        case .pushBytes(let d):
            additionalSize = d.count
        case .pushData1(let d):
            additionalSize = MemoryLayout<UInt8>.size + d.count
        case .pushData2(let d):
            additionalSize = MemoryLayout<UInt16>.size + d.count
        case .pushData4(let d):
            additionalSize = MemoryLayout<UInt32>.size + d.count
        default:
            additionalSize = 0
        }
        return MemoryLayout<UInt8>.size + additionalSize
    }
    
    var opCode: UInt8 {
        switch(self) {
        case .zero: 0x00
        case .pushBytes(let d): UInt8(d.count)
        case .pushData1(_): 0x4c
        case .pushData2(_): 0x4d
        case .pushData4(_): 0x4e
        case .oneNegate: 0x4f
        case .reserved(let k): k
        case .success(let k): k
        case .constant(let k): 0x50 + k
        case .noOp: 0x61
        case .ver: 0x62
        case .if: 0x63
        case .notIf: 0x64
        case .verIf: 0x65
        case .verNotIf: 0x66
        case .else: 0x67
        case .endIf: 0x68
        case .verify: 0x69
        case .return: 0x6a
        case .toAltStack: 0x6b
        case .fromAltStack: 0x6c
        case .twoDrop: 0x6d
        case .twoDup: 0x6e
        case .ifDup: 0x73
        case .drop: 0x75
        case .dup: 0x76
        case .swap: 0x7c
        case .equal: 0x87
        case .equalVerify: 0x88
        case .negate: 0x8f
        case .add: 0x93
        case .boolAnd: 0x9a
        case .ripemd160: 0xa6
        case .sha256: 0xa8
        case .hash160: 0xa9
        case .hash256: 0xaa
        case .codeSeparator: 0xab
        case .checkSig: 0xac
        case .checkSigVerify: 0xad
        case .checkMultiSig: 0xae
        case .checkMultiSigVerify: 0xaf
        case .checkLockTimeVerify: 0xb1
        case .checkSequenceVerify: 0xb2
        case .checkSigAdd: 0xba
        case .undefined: 0xff
        }
    }
    
    var keyword: String {
        switch(self) {
        case .zero: "OP_0"
        case .pushBytes(_): "OP_PUSHBYTES"
        case .pushData1(_): "OP_PUSHDATA1"
        case .pushData2(_): "OP_PUSHDATA2"
        case .pushData4(_): "OP_PUSHDATA4"
        case .oneNegate: "OP_1NEGATE"
        case .reserved(let k): "OP_RESERVED\(k == 80 ? "" : k == 137 ? "1" : "2")"
        case .success(let k): "OP_SUCCESS\(k)"
        case .constant(let k): "OP_\(k)"
        case .noOp: "OP_NOP"
        case .ver: "OP_VER"
        case .if: "OP_IF"
        case .notIf: "OP_NOTIF"
        case .verIf: "OP_VERIF"
        case .verNotIf: "OP_VERNOTIF"
        case .else: "OP_ELSE"
        case .endIf: "OP_ENDIF"
        case .verify: "OP_VERIFY"
        case .return: "OP_RETURN"
        case .toAltStack: "OP_TOALTSTACK"
        case .fromAltStack: "OP_FROMALTSTACK"
        case .twoDrop: "OP_2DROP"
        case .twoDup: "OP_2DUP"
        case .ifDup: "OP_IFDUP"
        case .drop: "OP_DROP"
        case .dup: "OP_DUP"
        case .swap: "OP_SWAP"
        case .equal: "OP_EQUAL"
        case .equalVerify: "OP_EQUALVERIFY"
        case .negate: "OP_NEGATE"
        case .add: "OP_ADD"
        case .boolAnd: "OP_BOOLAND"
        case .ripemd160: "OP_RIPEMD160"
        case .sha256: "OP_SHA256"
        case .hash160: "OP_HASH160"
        case .hash256: "OP_HASH256"
        case .codeSeparator: "OP_CODESEPARATOR"
        case .checkSig: "OP_CHECKSIG"
        case .checkSigVerify: "OP_CHECKSIGVERIFY"
        case .checkMultiSig: "OP_CHECKMULTISIG"
        case .checkMultiSigVerify: "OP_CHECKMULTISIGVERIFY"
        case .checkLockTimeVerify: "OP_CHECKLOCKTIMEVERIFY"
        case .checkSequenceVerify: "OP_CHECKSEQUENCEVERIFY"
        case .checkSigAdd: "OP_CHECKSIGADD"
        case .undefined: "undefined"
        }
    }
    
    func execute(stack: inout [Data], context: inout ScriptContext) throws {
        if !context.evaluateBranch {
            switch(self) {
            case .if, .notIf, .else, .endIf, .verIf, .verNotIf, .success(_):
                break
            default:
                return
            }
        }
        switch(self) {
        case .zero:
            opConstant(0, stack: &stack)
        case .pushBytes(let d), .pushData1(let d), .pushData2(let d), .pushData4(let d):
            opPushData(data: d, stack: &stack)
        case .oneNegate:
            opOneNegate(&stack)
        case .reserved(let k):
            precondition(k == 80 || (k >= 137 && k <= 138))
            throw ScriptError.invalidScript
        case .success(let k):
            precondition(k == 80 || k == 98 || (k >= 126 && k <= 129) || (k >= 131 && k <= 134) || (k >= 137 && k <= 138) || (k >= 141 && k <= 142) || (k >= 149 && k <= 153) || (k >= 187 && k <= 254) )
            opSuccess(context: &context)
        case .constant(let k):
            precondition(k > 0 && k < 17)
            opConstant(k, stack: &stack)
        case .noOp:
            break
        case .ver:
            throw ScriptError.invalidScript
        case .if:
            try opIf(&stack, context: &context)
        case .notIf:
            try opIf(&stack, isNotIf: true, context: &context)
        case .verIf, .verNotIf:
            throw ScriptError.invalidScript
        case .else:
            try opElse(context: &context)
        case .endIf:
            try opEndIf(context: &context)
        case .verify:
            try opVerify(&stack)
        case .return:
            throw ScriptError.invalidScript
        case .toAltStack:
            try opToAltStack(&stack, context: &context)
        case .fromAltStack:
            try opFromAltStack(&stack, context: &context)
        case .twoDrop:
            try op2Drop(&stack)
        case .twoDup:
            try op2Dup(&stack)
        case .ifDup:
            try opIfDup(&stack)
        case .drop:
            try opDrop(&stack)
        case .dup:
            try opDup(&stack)
        case .swap:
            try opSwap(&stack)
        case .equal:
            try opEqual(&stack)
        case .equalVerify:
            try opEqualVerify(&stack)
        case .negate:
            try opNegate(&stack)
        case .add:
            try opAdd(&stack)
        case .boolAnd:
            try opBoolAnd(&stack)
        case .ripemd160:
            try opRIPEMD160(&stack)
        case .sha256:
            try opSHA256(&stack)
        case .hash160:
            try opHash160(&stack)
        case .hash256:
            try opHash256(&stack)
        case .codeSeparator:
            break
        case .checkSig:
            try opCheckSig(&stack, context: context)
        case .checkSigVerify:
            try opCheckSigVerify(&stack, context: context)
        case .checkMultiSig:
            guard context.script.version == .legacy || context.script.version == .witnessV0 else {
                throw ScriptError.invalidScript
            }
            try opCheckMultiSig(&stack, context: context)
        case .checkMultiSigVerify:
            guard context.script.version == .legacy || context.script.version == .witnessV0 else {
                throw ScriptError.invalidScript
            }
            try opCheckMultiSigVerify(&stack, context: context)
        case .checkLockTimeVerify:
            try opCheckLockTimeVerify(&stack, context: context)
        case .checkSequenceVerify:
            try opCheckSequenceVerify(&stack, context: context)
        case .checkSigAdd:
            try opCheckSigAdd(&stack, context: context)
        case .undefined:
            throw ScriptError.invalidScript
        }
    }
    
    var asm: String {
        if case .pushBytes(let d) = self {
            return d.hex
        }
        switch(self) {
        case .zero:
            return "0"
        case .pushData1(let d), .pushData2(let d), .pushData4(let d):
            return "\(keyword) \(d.hex)"
        default:
            return keyword
        }
    }
    
    var data: Data {
        let opCodeData = withUnsafeBytes(of: opCode) { Data($0) }
        let lengthData: Data
        switch(self) {
        case .pushData1(let d):
            lengthData = withUnsafeBytes(of: UInt8(d.count)) { Data($0) }
        case .pushData2(let d):
            lengthData = withUnsafeBytes(of: UInt16(d.count)) { Data($0) }
        case .pushData4(let d):
            lengthData = withUnsafeBytes(of: UInt32(d.count)) { Data($0) }
        default:
            lengthData = Data()
        }
        let rawData: Data
        switch(self) {
        case .pushBytes(let d), .pushData1(let d), .pushData2(let d), .pushData4(let d):
            rawData = d
        default:
            rawData = Data()
        }
        return opCodeData + lengthData + rawData
    }

    private init?(pushOpCode opCode: UInt8, _ data: Data, version: ScriptVersion) {
        var data = data
        switch(opCode) {
        case 0x01 ... 0x4b:
            let byteCount = Int(opCode)
            guard data.count >= byteCount else { return nil }
            let d = Data(data[..<(data.startIndex + byteCount)])
            self = .pushBytes(d)
        case 0x4c ... 0x4e:
            let byteCount: Int
            if opCode == 0x4c {
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                byteCount = Int(pushDataCount)
            } else if opCode == 0x4d {
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt16.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                byteCount = Int(pushDataCount)
            } else {
                // opCode == 0x4e
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt32.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                byteCount = Int(pushDataCount)
            }
            guard data.count >= byteCount else { return nil }
            let d = Data(data[..<(data.startIndex + byteCount)])
            if opCode == 0x4c {
                self = .pushData1(d)
            } else if opCode == 0x4d {
                self = .pushData2(d)
            }
            // opCode == 0x4e
            self = .pushData4(d)
        default:
            preconditionFailure()
        }
    }

    init?(_ data: Data, version: ScriptVersion = .legacy) {
        var data = data
        guard data.count > 0 else {
            return nil
        }
        let opCode = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: opCode))
        
        switch(opCode) {

        // OP_ZERO
        case Self.zero.opCode: self = .zero

        // OP_PUSHBYTES, OP_PUSHDATA1, OP_PUSHDATA2, OP_PUSHDATA4
        case 0x01 ... 0x4e: self.init(pushOpCode: opCode, data, version: version)

        case Self.oneNegate.opCode: self = .oneNegate

        case Self.reserved(80).opCode,
             Self.reserved(137).opCode ... Self.reserved(138).opCode:
            self = if version == .legacy || version == .witnessV0 {
                .reserved(opCode)
            } else {
                .success(opCode)
            }

        // If any opcode numbered 80, 98, 126-129, 131-134, 137-138, 141-142, 149-153, 187-254 is encountered, validation succeeds
        case Self.success(126).opCode ... Self.success(129).opCode,
             Self.success(131).opCode ... Self.success(134).opCode,
             Self.success(141).opCode ... Self.success(142).opCode,
             Self.success(149).opCode ... Self.success(153).opCode,
             Self.success(187).opCode ... Self.success(254).opCode:
            self = .success(opCode)

        // Constants
        case Self.constant(1).opCode ... Self.constant(16).opCode:
            self = .constant(opCode - 0x50)

        case Self.noOp.opCode: self = .noOp

        // OP_VER / OP_SUCCESS
        case Self.ver.opCode:
            self = if version == .legacy || version == .witnessV0 {
                .ver
            } else {
                .success(opCode)
            }

        case Self.if.opCode: self = .if
        case Self.notIf.opCode: self = .notIf
        case Self.verIf.opCode: self = .verIf
        case Self.verNotIf.opCode: self = .verNotIf
        case Self.else.opCode: self = .else
        case Self.endIf.opCode: self = .endIf
        case Self.verify.opCode: self = .verify
        case Self.return.opCode: self = .return
        case Self.toAltStack.opCode: self = .toAltStack
        case Self.fromAltStack.opCode: self = .fromAltStack
        case Self.twoDrop.opCode: self = .twoDrop
        case Self.twoDup.opCode: self = .twoDup
        case Self.ifDup.opCode: self = .ifDup
        case Self.drop.opCode: self = .drop
        case Self.dup.opCode: self = .dup
        case Self.swap.opCode: self = .swap
        case Self.equal.opCode: self = .equal
        case Self.equalVerify.opCode: self = .equalVerify
        case Self.negate.opCode: self = .negate
        case Self.add.opCode: self = .add
        case Self.boolAnd.opCode: self = .boolAnd
        case Self.ripemd160.opCode: self = .ripemd160
        case Self.sha256.opCode: self = .sha256
        case Self.hash160.opCode: self = .hash160
        case Self.hash256.opCode: self = .hash256
        case Self.codeSeparator.opCode: self = .codeSeparator
        case Self.checkSig.opCode: self = .checkSig
        case Self.checkSigVerify.opCode: self = .checkSigVerify
        case Self.checkMultiSig.opCode: self = .checkMultiSig
        case Self.checkMultiSigVerify.opCode: self = .checkMultiSigVerify
        case Self.checkLockTimeVerify.opCode: self = .checkLockTimeVerify
        case Self.checkSequenceVerify.opCode: self = .checkSequenceVerify
        case Self.checkSigAdd.opCode: self = .checkSigAdd
        default: self = .undefined
        }
    }
}
