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
            Transaction.Output(value: 0, script:.init([]))
        ]
        let tx = Transaction(version: .v1, locktime: .disabled,
            inputs: [
                .init(txID: "", outIdx: 0, sequence: .initial)
            ],
            outputs: [
                Transaction.Output(value: 0, script:.init([]))
            ]
        )
        
        let script = Script([
            Op.checkSig
        ])
        let hashType = HashType.all
        let sig = signECDSA(msg: tx.sighash(hashType, inIdx: 0, prevOut: prevOuts[0], scriptCode: script, opIdx: 0), privKey: privKey) + hashType.data
        var stack = [
            sig,
            pubKey
        ]
        XCTAssertNoThrow(try script.run(&stack, tx: tx, inIdx: 0, prevOuts: prevOuts))
        let expectedStack = [Data]([.one])
        XCTAssertEqual(stack, expectedStack)
    }
}
