import XCTest
@testable import CornModel
import Foundation

/// https://en.bitcoin.it/wiki/OP_CHECKMULTISIG
final class CheckMultiSigTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    
    func testOneOfOne() {
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
            .constant(1),
            .pushBytes(publicKey),
            .constant(1),
            .checkMultiSig
        ])

        let sig = tx.createSignature(inputIndex: 0, secretKey: secretKey, sighashType: .all, previousOutput: previousOutputs[0], scriptCode: script.data)
        var stack = [
            Data(),
            sig
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
        let expectedStack = [Data]([.one])
        XCTAssertEqual(stack, expectedStack)
    }

    
    func testTwoOfThree() {
        let secretKeys = (0...2).map { _ in createSecretKey() }
        let publicKeys = secretKeys.map { getPublicKey(secretKey: $0) }
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
            .constant(2),
            .pushBytes(publicKeys[2]),
            .pushBytes(publicKeys[1]),
            .pushBytes(publicKeys[0]),
            .constant(3),
            .checkMultiSigVerify
        ])
        var sighashCache = Data?.none
        let allSigs = secretKeys.map {
            tx.createSignature(inputIndex: 0, secretKey: $0, sighashType: .all, previousOutput: previousOutputs[0], scriptCode: script.data, sighashCache: &sighashCache)
        }

        var stack = [
            Data(),
            allSigs[1],
            allSigs[0]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[0]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[1]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
        
        stack = [
            Data(),
            allSigs[1],
            allSigs[2]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, previousOutputs: previousOutputs))
    }
}
