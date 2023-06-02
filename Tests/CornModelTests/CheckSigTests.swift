import XCTest
@testable import CornModel
import Foundation

/// https://en.bitcoin.it/wiki/OP_CHECKSIG
final class CheckSigTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    
    func testOne() {
        let privKey = createPrivKey()
        let pubKey = getPubKey(privKey: privKey)
        let prevOuts = [
            Tx.Out(value: 0, scriptPubKey: .init([]))
        ]
        let tx = Tx(version: .v1, lockTime: 0,
            ins: [
                .init(txID: "", outIdx: 0, sequence: 0)
            ],
            outs: [
                Tx.Out(value: 0, scriptPubKey: .init([]))
            ]
        )
        
        let script = ScriptLegacy([
            .checkSig
        ])
        let hashType = HashType.all
        let sig = signECDSA(msg: tx.sigHash(hashType, inIdx: 0, prevOut: prevOuts[0], scriptCode: script, opIdx: 0), privKey: privKey) + hashType.data
        var stack = [
            sig,
            pubKey
        ]
        let result = script.run(stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
        var expectedStack = [Data]()
        expectedStack.pushInt(1)
        XCTAssertEqual(stack, expectedStack)
    }
}
