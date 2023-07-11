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
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial)
            ],
            outputs: [
                Transaction.Output(value: 0, script:.init([]))
            ]
        )
        
        let script = ParsedScript([
            .checkSig
        ])
        let sighashType = SighashType.all
        let sig = signECDSA(msg: tx.signatureHash(sighashType: sighashType, inputIndex: 0, previousOutput: prevOuts[0], scriptCode: script.data), privKey: privKey) + sighashType.data
        var stack = [
            sig,
            pubKey
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
        let expectedStack = [Data]([.one])
        XCTAssertEqual(stack, expectedStack)
    }
}
