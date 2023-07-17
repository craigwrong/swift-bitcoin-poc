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
        let zero = ScriptNumber.zero.data
        let one = ScriptNumber.one.data
        let two = withUnsafeBytes(of: Int32(2)) { Data($0) }
        let big = withUnsafeBytes(of: (Int32.max / 2) - 1) { Data($0) }
        
        var script = ParsedScript([.pushBytes(zero), .pushBytes(zero), .boolAnd])
        var stack = [Data]()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])

        script = ParsedScript([.pushBytes(zero), .pushBytes(one), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(zero), .pushBytes(two), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(zero), .pushBytes(big), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(one), .pushBytes(zero), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(two), .pushBytes(zero), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(big), .pushBytes(zero), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(big), .pushBytes(zero), .boolAnd])
        stack = .init()
        XCTAssertThrowsError(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [zero])
        
        script = ParsedScript([.pushBytes(one), .pushBytes(one), .boolAnd])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [one])
        
        script = ParsedScript([.pushBytes(one), .pushBytes(two), .boolAnd])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [one])
        
        script = ParsedScript([.pushBytes(two), .pushBytes(two), .boolAnd])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [one])
        
        script = ParsedScript([.pushBytes(big), .pushBytes(one), .boolAnd])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [one])
        
        script = ParsedScript([.pushBytes(big), .pushBytes(big), .boolAnd])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [one])
    }

    func testOpSuccess() {
        var script = ParsedScript([.success(80), .pushBytes(Data(repeating: 0, count: 128))], version: .witnessV1)
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [])

        script = ParsedScript([.success(98), .pushBytes(Data(repeating: 1, count: 128))], version: .witnessV1)
        stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [])

        script = ParsedScript([.success(254)], version: .witnessV1)
        stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [])

        let legacyScript = ParsedScript([.reserved(80)])
        stack = [Data]()
        XCTAssertThrowsError(try legacyScript.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [])
    }

    func testDrop() {
        let big = withUnsafeBytes(of: (Int.max / 2) - 1) { Data($0) }
        let script = ParsedScript([.pushBytes(big), .drop])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssert(stack.isEmpty)
    }

    func testDup() {
        let big = withUnsafeBytes(of: (Int.max / 2) - 1) { Data($0) }
        let script = ParsedScript([.pushBytes(big), .dup])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [big, big])
    }

    func testIf() {
        
        // If branch
        var script = ParsedScript([.constant(3), .constant(4), .add, .constant(7), .equal, .if, .constant(2), .constant(6), .add, .else, .constant(5), .endIf, .constant(10)
        ])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([0x08]), Data([0x0a])])
        
        // Missing else branch
        script = ParsedScript([.constant(3), .constant(4), .add, .constant(7), .equal, .if, .constant(2), .constant(6), .add, .endIf, .constant(10)
        ])
        stack = []
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([0x08]), Data([0x0a])])
        
        // Else branch
        script = ParsedScript([.constant(3), .constant(4), .add, .constant(9), .equal, .if, .constant(2), .constant(6), .add, .else, .constant(5), .endIf, .constant(10)
        ])
        stack = []
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([0x05]), Data([0x0a])])
        
        // Notif
        script = ParsedScript([.constant(3), .constant(4), .add, .constant(9), .equal, .notIf, .constant(5), .endIf, .constant(10)
        ])
        stack = []
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([0x05]), Data([0x0a])])
    }

    func testCheckSig() {
        let publicKey = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        let previousOutput = Transaction.Output(value: 0, script: .init(Data(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac")))

        let tx = Transaction(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022037b8b0c1a33caa83be5eb71f87bce5dbd4890a56a61b98d9d603e754313fadc602201ef00773d2e0b98d558f0a1ac89a1fad1da15f852140fca5f5d737c0025e11ad014104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))

        guard let sigOp = ParsedScript(tx.inputs[0].script.data)?.operations.first, case .pushBytes(let sig) = sigOp else {
            XCTFail("Could not extract signature from transaction.")
            return
        }

        let publicKeyHash = hash160(publicKey)

        let scriptSig = ParsedScript([.pushBytes(sig), .pushBytes(publicKey)])
        let scriptPubKey = ParsedScript([.dup, .hash160, .pushBytes(publicKeyHash), .equalVerify, .checkSig])

        var stack = [Data]()
        XCTAssertNoThrow(try scriptSig.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: [previousOutput]))
        XCTAssertNoThrow(try scriptPubKey.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: [previousOutput]))
        
        let expected = [Data]([ScriptNumber.one.data])
        XCTAssertEqual(stack, expected)

        XCTAssert(tx.verify(previousOutputs: [previousOutput]))
    }
}
