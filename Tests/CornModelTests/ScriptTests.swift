import XCTest
import CornModel
import BigInt

/// https://en.bitcoin.it/wiki/Script
final class ScriptTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    
    func testDrop() {
        let bigNummber = BigInt(UInt64.max) * 2
        let numberData = bigNummber.serialize()
        let script = Script([.pushBytes(numberData), .drop])
        var stack = [Data]()
        let dummyTx = Tx(version: .v1, ins: [], outs: [], witnessData: [], lockTime: 0)
        let result = script.run(stack: &stack, tx: dummyTx, prevOuts: [], inIdx: -1)
        XCTAssert(result)
        XCTAssert(stack.isEmpty)
    }

    func testDup() {
        let bigNummber = BigInt(UInt64.max) * 2
        let numberData = bigNummber.serialize()
        let script = Script([.pushBytes(numberData), .dup])
        var stack = [Data]()
        let dummyTx = Tx(version: .v1, ins: [], outs: [], witnessData: [], lockTime: 0)
        let result = script.run(stack: &stack, tx: dummyTx, prevOuts: [], inIdx: -1)
        XCTAssert(result)
        XCTAssertEqual(stack, [numberData, numberData])
    }

    func testCheckSig() {
        let pubKey = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        let prevOut = Tx.Out(value: UInt64(0), scriptPubKey: .init(Data(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"), includesLength: false))

        let tx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022037b8b0c1a33caa83be5eb71f87bce5dbd4890a56a61b98d9d603e754313fadc602201ef00773d2e0b98d558f0a1ac89a1fad1da15f852140fca5f5d737c0025e11ad014104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))

        let sigOp = tx.ins[0].scriptSig.ops[0]
        guard case .pushBytes(let sig) = sigOp else {
            XCTFail("Could not extract signature from transaction.")
            return
        }

        let pubKeyHash = hash160(pubKey)

        let script = Script([.pushBytes(sig), .pushBytes(pubKey), .dup, .hash160, .pushBytes(pubKeyHash), .equalVerify, .checkSig])

        var stack = [Data]()
        let result = script.run(stack: &stack, tx: tx, prevOuts: [prevOut], inIdx: 0)
        XCTAssert(result)
        XCTAssertEqual(stack, [BigInt(1).serialize()])
        XCTAssert(tx.verify(prevOuts: [prevOut]))
    }
}
