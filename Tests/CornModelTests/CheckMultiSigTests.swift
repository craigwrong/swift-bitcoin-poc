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
            .constant(1),
            .pushBytes(pubKey),
            .constant(1),
            .checkMultiSig
        ])
        let sighashType = SighashType.all
        let sig = signECDSA(msg: tx.signatureHash(sighashType: sighashType, inputIndex: 0, previousOutput: prevOuts[0], scriptCode: script.data), privKey: privKey) + sighashType.data
        var stack = [
            Data(),
            sig
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
        let expectedStack = [Data]([.one])
        XCTAssertEqual(stack, expectedStack)
    }

    
    func testTwoOfThree() {
        let privKeys = (0...2).map { _ in createPrivKey() }
        let pubKeys = privKeys.map { getPubKey(privKey: $0) }
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
            .constant(2),
            .pushBytes(pubKeys[2]),
            .pushBytes(pubKeys[1]),
            .pushBytes(pubKeys[0]),
            .constant(3),
            .checkMultiSigVerify
        ])
        let sighashType = SighashType.all
        let allSigs = privKeys.map {
            signECDSA(msg: tx.signatureHash(sighashType: sighashType, inputIndex: 0, previousOutput: prevOuts[0], scriptCode: script.data), privKey: $0) + sighashType.data
        }

        var stack = [
            Data(),
            allSigs[1],
            allSigs[0]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[0]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[1]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
        
        stack = [
            Data(),
            allSigs[1],
            allSigs[2]
        ]
        XCTAssertNoThrow(try script.run(&stack, transaction: tx, inputIndex: 0, prevOuts: prevOuts))
    }
}
