import XCTest
import CornModel

final class DataTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }
    
    override class func tearDown() {
        eccStop()
    }
    
    func testTx() {
        let privKey0 = createPrivKey()
        let pubKey0 = getPubKey(privKey: privKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let prevOuts = [
            Tx.Out(value: 0,
                   scriptPubKey: ScriptLegacy.makeP2PKH(pubKey: pubKey0)),
            Tx.Out(value: 0,
                   scriptPubKey: ScriptLegacy.makeP2PKH(pubKey: pubKey1))
        ]
        var tx = Tx(version: .v1, lockTime: .zero,
                    ins: [.init(txID: "", outIdx: 0, sequence: 0)],
                    outs: [.init(value: 0, scriptPubKey: .makeNullData(""))]
        )
        tx.signInput(privKeys: [privKey0], pubKeys: [pubKey0], hashType: .singleAnyCanPay, inIdx: 0, prevOuts: prevOuts)
        var res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        //signed.outs.removeAll()
        tx.outs.append(.init(value: 0, scriptPubKey: .makeNullData("")))
        res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        
        tx.ins.append(Tx.In(txID: "", outIdx: 0, sequence: 0))
        tx.signInput(privKeys: [privKey1], pubKeys: [pubKey1], hashType: .all, inIdx: 1, prevOuts: prevOuts)
        res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
    }
    
    func testSigHashAll() {
        // Some keys
        let privKey0 = createPrivKey()
        let pubKey0 = getPubKey(privKey: privKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let privKey2 = createPrivKey()
        let pubKey2 = getPubKey(privKey: privKey2)
        
        // Some previous outputs
        let prevOuts = [
            Tx.Out(value: 0,
                   scriptPubKey: ScriptLegacy.makeP2PKH(pubKey: pubKey0)),
            Tx.Out(value: 0,
                   scriptPubKey: ScriptLegacy.makeP2PKH(pubKey: pubKey1))
        ]
        
        let prevOutsPlus = prevOuts + [
            Tx.Out(value: 0,
                   scriptPubKey: ScriptLegacy.makeP2WKH(pubKey: pubKey2))
        ]
        
        // Our transaction with 2 ins and 2 outs
        var tx = Tx(
            version: .v1,
            lockTime: .zero,
            ins: [
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
            ],
            outs: [
                .init(value: 0, scriptPubKey: .makeNullData("")),
                .init(value: 0, scriptPubKey: .makeNullData(""))
            ]
        )
        
        // Sign both inputs
        tx.signInput(privKeys: [privKey0], pubKeys: [pubKey0], hashType: .allAnyCanPay, inIdx: 0, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKey1], pubKeys: [pubKey1], hashType: .noneAnyCanPay, inIdx: 1, prevOuts: prevOuts)
        
        // Verify the signed transaction as is
        var res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        
        // Appending an additional output
        var signedOneMoreOut = tx
        signedOneMoreOut.outs.append(.init(value: 0, scriptPubKey: .makeNullData("")))
        res = signedOneMoreOut.verify(prevOuts: prevOuts)
        XCTAssertFalse(res)
        
        // Removing one of the outputs
        var signedOutRemoved = tx
        signedOutRemoved.outs.remove(at: 0)
        res = signedOutRemoved.verify(prevOuts: prevOuts)
        XCTAssertFalse(res)
        
        // Appending an additional input
        var signedOneMoreIn = tx
        signedOneMoreIn.ins.append(.init(txID: "", outIdx: 0, sequence: 0))
        signedOneMoreIn.signInput(privKeys: [privKey2], pubKeys: [pubKey2], hashType: .noneAnyCanPay, inIdx: 2, prevOuts: prevOutsPlus)
        res = signedOneMoreIn.verify(prevOuts: prevOutsPlus)
        XCTAssert(res)
        
        // Removing the last one of the ins
        var signedInRemoved = tx
        signedInRemoved.ins.remove(at: 1)
        res = signedInRemoved.verify(prevOuts: [prevOuts[0]])
        XCTAssert(res)
    }
    
    func testMultipleInputTypes() {
        let privKeys = (0...10).map { _ in createPrivKey() }
        let pubKeys = privKeys.map { getPubKey(privKey: $0) }
        
        let redeemScript2 = ScriptLegacy.init([
            .constant(2),
            .pushBytes(pubKeys[3]),
            .pushBytes(pubKeys[2]),
            .constant(2),
            .checkMultiSig
        ])

        let redeemScript4 = ScriptLegacy.makeP2WKH(pubKey: pubKeys[4])
        let redeemScript5 = ScriptV0.init([
            .constant(2),
            .pushBytes(pubKeys[6]),
            .pushBytes(pubKeys[5]),
            .constant(2),
            .checkMultiSig
        ])
        let redeemScriptV06 = ScriptV0.init([
            .constant(2),
            .pushBytes(pubKeys[7]),
            .pushBytes(pubKeys[6]),
            .constant(2),
            .checkMultiSig
        ])
        let redeemScript6 = ScriptLegacy.makeP2WSH(redeemScriptV0: redeemScriptV06)
        
        let outputKey7 = getOutputKey(privKey: privKeys[7])

        // Sprevious outputs
        let prevOuts = [
            // p2pk
            Tx.Out(value: 0, scriptPubKey: ScriptLegacy.makeP2PK(pubKey: pubKeys[0])),
            
            // p2pkh
            Tx.Out(value: 0, scriptPubKey: ScriptLegacy.makeP2PKH(pubKey: pubKeys[1])),
            
            // p2sh
            Tx.Out( value: 0,
                scriptPubKey: ScriptLegacy.makeP2SH(redeemScript: redeemScript2)
            ),
            
            // p2wkh
            Tx.Out(value: 0, scriptPubKey: ScriptLegacy.makeP2WKH(pubKey: pubKeys[3])),
            
            // p2sh-p2wkh
            Tx.Out(value: 0,
                scriptPubKey: ScriptLegacy.makeP2SH(redeemScript: redeemScript4)
            ),

            // p2wsh
            Tx.Out(value: 0,
                scriptPubKey: ScriptLegacy.makeP2WSH(redeemScriptV0: redeemScript5)
            ),

            // p2sh-p2wsh
            Tx.Out(value: 0,
                scriptPubKey: ScriptLegacy.makeP2SH(redeemScript: redeemScript6)
            ),

            // p2tr (key path)
            Tx.Out(value: 0,
                scriptPubKey: ScriptLegacy.makeP2TR(outputKey: outputKey7)
            ),
            
            // legacy multisig
            Tx.Out(value: 0,
                scriptPubKey: .init([
                    .constant(2),
                    .pushBytes(pubKeys[9]),
                    .pushBytes(pubKeys[8]),
                    .constant(2),
                    .checkMultiSig
                ])
            )
        ]
        
        // Our transaction with 6 ins and 2 outs
        var tx = Tx(
            version: .v1,
            lockTime: .zero,
            ins: [
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
            ],
            outs: [
                .init(value: 0, scriptPubKey: .makeNullData("")),
                .init(value: 0, scriptPubKey: .makeNullData(""))
            ]
        )
        tx.signInput(privKeys: [privKeys[0]], hashType: .all, inIdx: 0, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[1]], pubKeys: [pubKeys[1]], hashType: .all, inIdx: 1, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[2], privKeys[3]], redeemScript: redeemScript2, hashType: .all, inIdx: 2, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[3]], pubKeys: [pubKeys[3]], hashType: .all, inIdx: 3, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[4]], pubKeys: [pubKeys[4]], redeemScript: redeemScript4, hashType: .all, inIdx: 4, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[5], privKeys[6]], redeemScriptV0: redeemScript5, hashType: .all, inIdx: 5, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[6], privKeys[7]], redeemScript: redeemScript6, redeemScriptV0: redeemScriptV06, hashType: .all, inIdx: 6, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[7]], tapscript: .none, inIdx: 7, prevOuts: prevOuts)
        tx.signInput(privKeys: [privKeys[8], privKeys[9]], hashType: .all, inIdx: 8, prevOuts: prevOuts)
        
        let res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
    }
}
