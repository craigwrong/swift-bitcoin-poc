import Foundation

/// The TapRoot Script (Tapscript) Common Message Extension as defined in BIP342
struct TapscriptExt: Equatable {
    // We define the tapscript message extension ext to BIP341 Common Signature Message, indicated by ext_flag = 1:
    var tapLeafHash: Data // tapleaf_hash (32): the tapleaf hash as defined in BIP341
    var keyVersion: UInt8 // key_version (1): a constant value 0x00 representing the current version of public keys in the tapscript signature opcode execution.
    var codesepPos: UInt32 // codesep_pos (4): the opcode position of the last executed OP_CODESEPARATOR before the currently executed signature opcode, with the value in little endian (or 0xffffffff if none executed). The first opcode in a script has a position of 0. A multi-byte push opcode is counted as one opcode, regardless of the size of data being pushed. Opcodes in parsed but unexecuted branches count towards this value as well

    var data: Data {
        var ret = tapLeafHash
        ret += withUnsafeBytes(of: keyVersion) { Data($0) }
        ret += withUnsafeBytes(of: codesepPos) { Data($0) }
        return ret
    }
}
