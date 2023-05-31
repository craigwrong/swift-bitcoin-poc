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
        let pubKeyHash0 = hash160(pubKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let pubKeyHash1 = hash160(pubKey1)
        let spentOut0 = Tx.Out(value: 0,
                               scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHash0]).data)
        let spentOut1 = Tx.Out(value: 0,
                               scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHash1]).data)
        var tx = Tx(version: .v1, lockTime: .zero,
                    ins: [.init(txID: "", outIdx: 0, sequence: 0)],
                    outs: [.init(value: 0, scriptPubKeyData: Data())]
        )
        tx.sign(privKey: privKey0, pubKey: pubKey0, hashType: .singleAnyCanPay, inIdx: 0, prevOut: spentOut0)
        var res = tx.verify(prevOuts: [spentOut0])
        XCTAssert(res)
        //signed.outs.removeAll()
        tx.outs.append(.init(value: 0, scriptPubKeyData: .init()))
        res = tx.verify(prevOuts: [spentOut0])
        XCTAssert(res)
        
        tx.ins.append(Tx.In(txID: "", outIdx: 0, sequence: 0))
        tx.sign(privKey: privKey1, pubKey: pubKey1, hashType: .all, inIdx: 1, prevOut: spentOut1)
        res = tx.verify(prevOuts: [spentOut0, spentOut1])
        XCTAssert(res)
    }
    
    func testSigHashAll() {
        // Some keys
        let privKey0 = createPrivKey()
        let pubKey0 = getPubKey(privKey: privKey0)
        let pubKeyHash0 = hash160(pubKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let pubKeyHash1 = hash160(pubKey1)
        let privKey2 = createPrivKey()
        let pubKey2 = getPubKey(privKey: privKey2)
        let pubKeyHash2 = hash160(pubKey2)
        
        // Some previous outputs
        let spentOut0 = Tx.Out(value: 0,
                               scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHash0]).data)
        
        let spentOut1 = Tx.Out(value: 0,
                               scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHash1]).data)
        let spentOut2 = Tx.Out(value: 0,
                               scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHash2]).data)
        
        // Our transaction with 2 ins and 2 outs
        var tx = Tx(
            version: .v1,
            lockTime: .zero,
            ins: [
                .init(txID: "", outIdx: 0, sequence: 0),
                .init(txID: "", outIdx: 0, sequence: 0),
            ],
            outs: [
                .init(value: 0, scriptPubKeyData: Data()),
                .init(value: 0, scriptPubKeyData: Data())
            ]
        )
        
        // Sign both inputs
        tx.sign(privKey: privKey0, pubKey: pubKey0, hashType: .allAnyCanPay, inIdx: 0, prevOut: spentOut0)
        tx.sign(privKey: privKey1, pubKey: pubKey1, hashType: .noneAnyCanPay, inIdx: 1, prevOut: spentOut1)
        
        // Verify the signed transaction as is
        var res = tx.verify(prevOuts: [spentOut0, spentOut1])
        XCTAssert(res)
        
        // Appending an additional output
        var signedOneMoreOut = tx
        signedOneMoreOut.outs.append(.init(value: 0, scriptPubKeyData: .init()))
        res = signedOneMoreOut.verify(prevOuts: [spentOut0, spentOut1])
        XCTAssertFalse(res)
        
        // Removing one of the outputs
        var signedOutRemoved = tx
        signedOutRemoved.outs.remove(at: 0)
        res = signedOutRemoved.verify(prevOuts: [spentOut0, spentOut1])
        XCTAssertFalse(res)
        
        // Appending an additional input
        var signedOneMoreIn = tx
        signedOneMoreIn.ins.append(.init(txID: "", outIdx: 0, sequence: 0))
        signedOneMoreIn.sign(privKey: privKey2, pubKey: pubKey2, hashType: .noneAnyCanPay, inIdx: 2, prevOut: spentOut2)
        res = signedOneMoreIn.verify(prevOuts: [spentOut0, spentOut1, spentOut2])
        XCTAssert(res)
        
        // Removing the last one of the ins
        var signedInRemoved = tx
        signedInRemoved.ins.remove(at: 1)
        res = signedInRemoved.verify(prevOuts: [spentOut0])
        XCTAssert(res)
    }
    
    func testMultipleInputTypes() {
        let privKeys = (0...8).map { _ in createPrivKey() }
        let pubKeys = privKeys.map { getPubKey(privKey: $0) }
        let pubKeyHashes = pubKeys.map { hash160($0) }
        
        let redeemScript2 = ScriptLegacy.withType(.pubKey, data: [pubKeys[2]])
        let redeemScript4 = ScriptLegacy.withType(.witnessV0KeyHash, data: [pubKeyHashes[4]])
        let redeemScript5 = ScriptV0.init([.drop, .constant(1)])
        let redeemScriptV06 = ScriptV0.init([.drop, .constant(1)])
        let redeemScript6 = ScriptLegacy.withType(.witnessV0ScriptHash, data: [
            sha256(redeemScriptV06.data)
        ])

        let (outputKey7, _) = createTapTweak(pubKey: getInternalKey(privKey: privKeys[7]), merkleRoot: .none)

        // Sprevious outputs
        let prevOuts = [
            // p2pk
            Tx.Out(value: 0, scriptPubKeyData: ScriptLegacy.withType(.pubKey, data: [pubKeys[0]]).data),
            
            // p2pkh
            Tx.Out(value: 0, scriptPubKeyData: ScriptLegacy.withType(.pubKeyHash, data: [pubKeyHashes[1]]).data),
            
            // p2sh
            Tx.Out( value: 0,
                scriptPubKeyData: ScriptLegacy.withType(.scriptHash, data: [
                    hash160(redeemScript2.data)
                ]).data
            ),
            
            // p2wkh
            Tx.Out(value: 0, scriptPubKeyData: ScriptLegacy.withType(.witnessV0KeyHash, data: [pubKeyHashes[3]]).data),
            
            // p2sh-p2wkh
            Tx.Out(value: 0,
                scriptPubKeyData: ScriptLegacy.withType(.scriptHash, data: [
                    hash160(redeemScript4.data)
                ]).data
            ),

            // p2wsh
            Tx.Out(value: 0,
                scriptPubKeyData: ScriptLegacy.withType(.witnessV0ScriptHash, data: [sha256(redeemScript5.data)]).data
            ),

            // p2sh-p2wsh
            Tx.Out(value: 0,
                scriptPubKeyData: ScriptLegacy.withType(.scriptHash, data: [
                    hash160(redeemScript6.data)
            ]).data),

            // p2tr (key path)
            Tx.Out(value: 0,
                scriptPubKeyData: ScriptLegacy.withType(.witnessV1TapRoot, data: [outputKey7]).data
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
            ],
            outs: [
                .init(value: 0, scriptPubKeyData: Data()),
                .init(value: 0, scriptPubKeyData: Data())
            ]
        )
        tx.signInput(privKey: privKeys[0], pubKey: pubKeys[0], hashType: .all, inIdx: 0, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[1], pubKey: pubKeys[1], hashType: .all, inIdx: 1, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[2], pubKey: pubKeys[2], redeemScript: redeemScript2, hashType: .all, inIdx: 2, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[3], pubKey: pubKeys[3], hashType: .all, inIdx: 3, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[4], pubKey: pubKeys[4], redeemScript: redeemScript4, hashType: .all, inIdx: 4, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[5], pubKey: pubKeys[5], redeemScript: redeemScript5, hashType: .all, inIdx: 5, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[6], pubKey: pubKeys[6], redeemScript: redeemScript6, redeemScriptV0: redeemScriptV06, hashType: .all, inIdx: 6, prevOuts: prevOuts)
        tx.signInput(privKey: privKeys[7], pubKey: pubKeys[7], hashType: .all, inIdx: 7, prevOuts: prevOuts)
        
        let res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
    }
}
