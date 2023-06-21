import XCTest
@testable import CornModel

/// https://en.bitcoin.it/wiki/Script
final class ScriptTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    
    func testBoolAnd() {
        let zero = Data.zero
        let one = Data.one
        let two = withUnsafeBytes(of: Int32(2)) { Data($0) }
        let big = withUnsafeBytes(of: (Int32.max / 2) - 1) { Data($0) }
        
        var script = [Op.pushBytes(zero), .pushBytes(zero), .boolAnd]
        var stack = [Data]()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])

        script = [Op.pushBytes(zero), .pushBytes(one), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(zero), .pushBytes(two), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(zero), .pushBytes(big), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(one), .pushBytes(zero), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(two), .pushBytes(zero), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(big), .pushBytes(zero), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(big), .pushBytes(zero), .boolAnd]
        stack = .init()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = [Op.pushBytes(one), .pushBytes(one), .boolAnd]
        stack = .init()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [one])
        
        script = [Op.pushBytes(one), .pushBytes(two), .boolAnd]
        stack = .init()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [one])
        
        script = [Op.pushBytes(two), .pushBytes(two), .boolAnd]
        stack = .init()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [one])
        
        script = [Op.pushBytes(big), .pushBytes(one), .boolAnd]
        stack = .init()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [one])
        
        script = [Op.pushBytes(big), .pushBytes(big), .boolAnd]
        stack = .init()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [one])
    }

    func testOpSuccess() {
        var script = [Op.success(80), .pushBytes(Data(repeating: 0, count: 128))]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [], version: .witnessV1))
        XCTAssertEqual(stack, [])

        script = [Op.success(98), .pushBytes(Data(repeating: 1, count: 128))]
        stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [], version: .witnessV1))
        XCTAssertEqual(stack, [])

        script = [Op.success(254)]
        stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: [], version: .witnessV1))
        XCTAssertEqual(stack, [])

        let legacyScript = [Op.reserved(80)]
        stack = [Data]()
        XCTAssertThrowsError(try runScript(legacyScript, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
    }

    func testDrop() {
        let big = withUnsafeBytes(of: (Int.max / 2) - 1) { Data($0) }
        let script = [Op.pushBytes(big), .drop]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssert(stack.isEmpty)
    }

    func testDup() {
        let big = withUnsafeBytes(of: (Int.max / 2) - 1) { Data($0) }
        let script = [Op.pushBytes(big), .dup]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [big, big])
    }

    func testIf() {
        
        // If branch
        var script = [Op.constant(3), .constant(4), .add, .constant(7), .equal, .if, .constant(2), .constant(6), .add, .else, .constant(5), .endIf, .constant(10)
        ]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([0x08]), Data([0x0a])])
        
        // Missing else branch
        script = [.constant(3), .constant(4), .add, .constant(7), .equal, .if, .constant(2), .constant(6), .add, .endIf, .constant(10)
        ]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([0x08]), Data([0x0a])])
        
        // Else branch
        script = [.constant(3), .constant(4), .add, .constant(9), .equal, .if, .constant(2), .constant(6), .add, .else, .constant(5), .endIf, .constant(10)
        ]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([0x05]), Data([0x0a])])
        
        // Notif
        script = [.constant(3), .constant(4), .add, .constant(9), .equal, .notIf, .constant(5), .endIf, .constant(10)
        ]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([0x05]), Data([0x0a])])
    }

    func testCheckSig() {
        let pubKey = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        let prevOut = Transaction.Output(value: 0, scriptData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))

        let tx = Transaction(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022037b8b0c1a33caa83be5eb71f87bce5dbd4890a56a61b98d9d603e754313fadc602201ef00773d2e0b98d558f0a1ac89a1fad1da15f852140fca5f5d737c0025e11ad014104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))

        guard let sigOp = tx.inputs[0].script?[0], case .pushBytes(let sig) = sigOp else {
            XCTFail("Could not extract signature from transaction.")
            return
        }

        let pubKeyHash = hash160(pubKey)

        let scriptSig = [Op.pushBytes(sig), .pushBytes(pubKey)]
        let scriptPubKey = [Op.dup, .hash160, .pushBytes(pubKeyHash), .equalVerify, .checkSig]

        var stack = [Data]()
        XCTAssertNoThrow(try runScript(scriptSig, stack: &stack, tx: tx, inIdx: 0, prevOuts: [prevOut]))
        XCTAssertNoThrow(try runScript(scriptPubKey, stack: &stack, tx: tx, inIdx: 0, prevOuts: [prevOut]))
        
        let expected = [Data]([.one])
        XCTAssertEqual(stack, expected)

        XCTAssert(tx.verify(prevOuts: [prevOut]))
    }
}
