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
        let spentOut = Tx.Out(
            value: 1_000_000,
            scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(Data(hex: "b44afd6e2b4dd224e3eb7050c46dd11f9be78a96")),
                .equalVerify,
                .checkSig
            ]).data
        )
        let unsigned = Tx(
            version: .v1,
            ins: [
                .init(
                    txID: "0000000000000000000000000000000000000000000000000000000000000000",
                    outIdx: 0,
                    scriptSig: .init([]),
                    sequence: 0
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
            ],
            witnessData: [],
            lockTime: .zero
        )
    }
}
