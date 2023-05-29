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
        let spentOut0 = Tx.Out(
            value: 1_000_000,
            scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(pubKeyHash0),
                .equalVerify,
                .checkSig
            ]).data
        )
        let spentOut1 = Tx.Out(
            value: 500_000,
            scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(pubKeyHash1),
                .equalVerify,
                .checkSig
            ]).data
        )
        let unsigned = Tx(
            version: .v1,
            lockTime: .zero,
            ins: [
                .init(
                    txID: "0000000000000000000000000000000000000000000000000000000000000000",
                    outIdx: 0,
                    sequence: 0,
                    scriptSig: .init([])
                )
            ],
            outs: [
                .init(
                    value: 1_000_000,
                    scriptPubKeyData: ScriptLegacy([
                        .dup,
                        .hash160,
                        .pushBytes(Data(hex: "b44afd6e2b4dd224e3eb7050c46dd11f9be78a96")),
                        .equalVerify,
                        .checkSig
                    ]).data
                )
            ]
        )
        var signed = unsigned.signed(privKey: privKey0, pubKey: pubKey0, hashType: .singleAnyCanPay, inIdx: 0, prevOut: spentOut0)
        let verificationResult = signed.verify(prevOuts: [spentOut0])
        XCTAssert(verificationResult)
        //signed.outs.removeAll()
        signed.outs.append(.init(value: 500, scriptPubKeyData: .init()))
        let verificationResult2 = signed.verify(prevOuts: [spentOut0])
        XCTAssert(verificationResult2)

        signed.ins.append(
            Tx.In(
                txID: "0000000000000000000000000000000000000000000000000000000000000000",
                outIdx: 0,
                sequence: 0,
                scriptSig: .init([])
            )
        )
        signed = signed.signed(privKey: privKey1, pubKey: pubKey1, hashType: .all, inIdx: 1, prevOut: spentOut1)
        let verificationResult3 = signed.verify(prevOuts: [spentOut0, spentOut1])
        XCTAssert(verificationResult3)
    }
}
