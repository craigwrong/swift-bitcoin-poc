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
        
        let script = [
            Op.constant(1),
            .pushBytes(pubKey),
            .constant(1),
            .checkMultiSig
        ]
        let hashType = HashType.all
        let sig = signECDSA(msg: tx.sighash(hashType, inIdx: 0, prevOut: prevOuts[0], scriptCode: script, opIdx: 0), privKey: privKey) + hashType.data
        var stack = [
            Data(),
            sig
        ]
        let result = runScript(script, stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
        var expectedStack = [Data]()
        expectedStack.pushInt(1)
        XCTAssertEqual(stack, expectedStack)
    }

    
    func testTwoOfThree() {
        let privKeys = (0...2).map { _ in createPrivKey() }
        let pubKeys = privKeys.map { getPubKey(privKey: $0) }
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
        
        let script = [
            Op.constant(2),
            .pushBytes(pubKeys[2]),
            .pushBytes(pubKeys[1]),
            .pushBytes(pubKeys[0]),
            .constant(3),
            .checkMultiSigVerify
        ]
        let hashType = HashType.all
        let allSigs = privKeys.map {
            signECDSA(msg: tx.sighash(hashType, inIdx: 0, prevOut: prevOuts[0], scriptCode: script, opIdx: 0), privKey: $0) + hashType.data
        }

        var stack = [
            Data(),
            allSigs[1],
            allSigs[0]
        ]
        var result = runScript(script, stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[0]
        ]
        result = runScript(script, stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
        
        stack = [
            Data(),
            allSigs[2],
            allSigs[1]
        ]
        result = runScript(script, stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
        
        stack = [
            Data(),
            allSigs[1],
            allSigs[2]
        ]
        result = runScript(script, stack: &stack, tx: tx, inIdx: 0, prevOuts: prevOuts)
        XCTAssert(result)
    }
}
