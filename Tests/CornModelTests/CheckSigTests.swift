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
        let secretKey = createSecretKey()
        let publicKey = getPublicKey(secretKey: secretKey)
        let previousOutputs = [
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
        let sig = tx.createSignature(inputIndex: 0, secretKey: secretKey, sighashType: sighashType, previousOutput: previousOutputs[0], scriptCode: script.data)
        var stack = [
            sig,
            publicKey
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
        let expectedStack = [Data]([.one])
        XCTAssertEqual(stack, expectedStack)
    }
}
