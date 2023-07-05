import Foundation

public extension Script { enum Operation: Equatable {
    case zero, pushBytes(Data), pushData1(Data), pushData2(Data), pushData4(Data), oneNegate, /* legacy,V0 */ reserved(UInt8), /* V1+ */ success(UInt8), constant(UInt8), noOp, ver, `if`, notIf, verIf, verNotIf, `else`, endIf, verify, `return`, toAltStack, fromAltStack, ifDup, drop, dup, equal, equalVerify, negate, add, boolAnd, ripemd160, sha256, hash160, hash256, codeSeparator, checkSig, checkSigVerify, checkMultiSig, checkMultiSigVerify, checkLockTimeVerify, checkSequenceVerify, /* V1+ */ checkSigAdd, undefined
} }

extension Script.Operation {
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
        case .zero:
            return 0x00
        case .pushBytes(let d):
            precondition(d.count >= 0x01 && d.count <= 0x4b)
            return UInt8(d.count)
        case .pushData1(_):
            return 0x4c
        case .pushData2(_):
            return 0x4d
        case .pushData4(_):
            return 0x4e
        case .oneNegate:
            return 0x4f
        case .reserved(let k):
            precondition(k == 80 || (k >= 137 && k <= 138))
            return k
        case .success(let k):
            // https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki
            // 80, 98, 126-129, 131-134, 137-138, 141-142, 149-153, 187-254
            precondition(k == 80 || k == 98 || (k >= 126 && k <= 129) || (k >= 131 && k <= 134) || (k >= 137 && k <= 138) || (k >= 141 && k <= 142) || (k >= 149 && k <= 153) || (k >= 187 && k <= 254) )
            return k
        case .constant(let k):
            precondition(k > 0 && k < 17)
            return 0x50 + k
        case .noOp:
            return 0x61
        case .ver:
            return 0x62
        case .if:
            return 0x63
        case .notIf:
            return 0x64
        case .verIf:
            return 0x65
        case .verNotIf:
            return 0x66
        case .else:
            return 0x67
        case .endIf:
            return 0x68
        case .verify:
            return 0x69
        case .return:
            return 0x6a
        case .toAltStack:
            return 0x6b
        case .fromAltStack:
            return 0x6c
        case .ifDup:
            return 0x73
        case .drop:
            return 0x75
        case .dup:
            return 0x76
        case .equal:
            return 0x87
        case .equalVerify:
            return 0x88
        case .negate:
            return 0x8f
        case .add:
            return 0x93
        case .boolAnd:
            return 0x9a
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
        case .checkLockTimeVerify:
            return 0xb1
        case .checkSequenceVerify:
            return 0xb2
        case .checkSigAdd:
            return 0xba
        case .undefined:
            return 0xff
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
        case .reserved(let k):
            precondition(k == 80 || (k >= 137 && k <= 138))
            return "OP_RESERVED\(k == 80 ? "" : k == 137 ? "1" : "2")"
        case .success(let k):
            precondition(k == 80 || k == 98 || (k >= 126 && k <= 129) || (k >= 131 && k <= 134) || (k >= 137 && k <= 138) || (k >= 141 && k <= 142) || (k >= 149 && k <= 153) || (k >= 187 && k <= 254) )
            // https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki
            // These opcodes are renamed to OP_SUCCESS80, ..., OP_SUCCESS254, and collectively known as OP_SUCCESSx[1].
            return "OP_SUCCESS\(k)"
        case .constant(let k):
            precondition(k > 0 && k < 17)
            return "OP_\(k)"
        case .noOp:
            return "OP_NOP"
        case .ver:
            return "OP_VER"
        case .if:
            return "OP_IF"
        case .notIf:
            return "OP_NOTIF"
        case .verIf:
            return "OP_VERIF"
        case .verNotIf:
            return "OP_VERNOTIF"
        case .else:
            return "OP_ELSE"
        case .endIf:
            return "OP_ENDIF"
        case .verify:
            return "OP_VERIFY"
        case .return:
            return "OP_RETURN"
        case .toAltStack:
            return "OP_TOALTSTACK"
        case .fromAltStack:
            return "OP_FROMALTSTACK"
        case .ifDup:
            return "OP_IFDUP"
        case .drop:
            return "OP_DROP"
        case .dup:
            return "OP_DUP"
        case .equal:
            return "OP_EQUAL"
        case .equalVerify:
            return "OP_EQUALVERIFY"
        case .negate:
            return "OP_NEGATE"
        case .add:
            return "OP_ADD"
        case .boolAnd:
            return "OP_BOOLAND"
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
        case .checkLockTimeVerify:
            return "OP_CHECKLOCKTIMEVERIFY"
        case .checkSequenceVerify:
            return "OP_CHECKSEQUENCEVERIFY"
        case .checkSigAdd:
            return "OP_CHECKSIGADD"
        case .undefined:
            return "undefined"
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
        case .ifDup:
            try opIfDup(&stack)
        case .drop:
            try opDrop(&stack)
        case .dup:
            try opDup(&stack)
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
        guard let keyword else {
            fatalError()
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
    
    init(_ data: Data, version: Script.Version) {
        var data = data
        let opCode = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
        data = data.dropFirst(MemoryLayout.size(ofValue: opCode))
        switch(opCode) {
        case Self.zero.opCode:
            self = .zero
        case 0x01 ... 0x4b:
            let d = Data(data[data.startIndex ..< data.startIndex + Int(opCode)])
            self = .pushBytes(d)
        case 0x4c ... 0x4e:
            let pushDataCountInt: Int
            if opCode == 0x4c {
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt8.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                pushDataCountInt = Int(pushDataCount)
            } else if opCode == 0x4d {
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt16.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                pushDataCountInt = Int(pushDataCount)
            } else if opCode == 0x4e {
                let pushDataCount = data.withUnsafeBytes {  $0.load(as: UInt32.self) }
                data = data.dropFirst(MemoryLayout.size(ofValue: pushDataCount))
                pushDataCountInt = Int(pushDataCount)
            } else {
                fatalError() // We should never arrive here.
            }
            let d = Data(data[data.startIndex ..< data.startIndex + pushDataCountInt])
            if opCode == 0x4c {
                self = .pushData1(d)
            } else if opCode == 0x4d {
                self = .pushData2(d)
            }
            self = .pushData4(d)
        case Self.oneNegate.opCode:
            self = .oneNegate
        case
            Self.reserved(80).opCode,
            Self.reserved(137).opCode ... Self.reserved(138).opCode:
            if version == .legacy || version == .witnessV0 {
                self = .reserved(opCode)
            } else {
                self = .success(opCode)
            }
        case
            // If any opcode numbered 80, 98, 126-129, 131-134, 137-138, 141-142, 149-153, 187-254 is encountered, validation succeeds
            Self.success(126).opCode ... Self.success(129).opCode,
            Self.success(131).opCode ... Self.success(134).opCode,
            Self.success(141).opCode ... Self.success(142).opCode,
            Self.success(149).opCode ... Self.success(153).opCode,
            Self.success(187).opCode ... Self.success(254).opCode:
            self = .success(opCode)
        case Self.constant(1).opCode ... Self.constant(16).opCode:
            self = .constant(opCode - 0x50)
        case Self.noOp.opCode:
            self = .noOp
        case Self.ver.opCode:
            if version == .legacy || version == .witnessV0 {
                self = .ver
            } else {
                self = .success(opCode)
            }
        case Self.if.opCode:
            self = .if
        case Self.notIf.opCode:
            self = .notIf
        case Self.verIf.opCode:
            self = .verIf
        case Self.verNotIf.opCode:
            self = .verNotIf
        case Self.else.opCode:
            self = .else
        case Self.endIf.opCode:
            self = .endIf
        case Self.verify.opCode:
            self = .verify
        case Self.return.opCode:
            self = .return
        case Self.toAltStack.opCode:
            self = .toAltStack
        case Self.fromAltStack.opCode:
            self = .fromAltStack
        case Self.ifDup.opCode:
            self = .ifDup
        case Self.drop.opCode:
            self = .drop
        case Self.dup.opCode:
            self = .dup
        case Self.equal.opCode:
            self = .equal
        case Self.equalVerify.opCode:
            self = .equalVerify
        case Self.negate.opCode:
            self = .negate
        case Self.add.opCode:
            self = .add
        case Self.boolAnd.opCode:
            self = .boolAnd
        case Self.ripemd160.opCode:
            self = .ripemd160
        case Self.sha256.opCode:
            self = .sha256
        case Self.hash160.opCode:
            self = .hash160
        case Self.hash256.opCode:
            self = .hash256
        case Self.codeSeparator.opCode:
            self = .codeSeparator
        case Self.checkSig.opCode:
            self = .checkSig
        case Self.checkSigVerify.opCode:
            self = .checkSigVerify
        case Self.checkMultiSig.opCode:
            self = .checkMultiSig
        case Self.checkMultiSigVerify.opCode:
            self = .checkMultiSigVerify
        case Self.checkLockTimeVerify.opCode:
            self = .checkLockTimeVerify
        case Self.checkSequenceVerify.opCode:
            self = .checkSequenceVerify
        case Self.checkSigAdd.opCode:
            self = .checkSigAdd
        default:
            self = .undefined
        // fatalError("Unknown operation code.")
        }
    }
}
