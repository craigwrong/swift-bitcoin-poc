import XCTest
import CornModel
import ECCHelper

final class HashTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }

    func testDoubleHash() {
        let sequence = Data(hex: "eeffffffffffffff")
        XCTAssertEqual(hash256(sequence).hex, "52b0a642eea2fb7ae638c36f6252b6750293dbe574a806984b8e4d8548339a3b")
        let prevOuts = "fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f00000000ef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a01000000"
        XCTAssertEqual(hash256(Data(hex: prevOuts)).hex, "96b827c8483d4e9b96712b6713a7b68d6e8003a781feba36c31143470b4efd37")

    }

    func testHash160() {
        let pubKey = Data(hex: "025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357")
        XCTAssertEqual(hash160(pubKey).hex, "1d0f172a0ecb48aee1be1f2687d2963ae33f71a1")
    }
    
    
    func testHashData() {
        // https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#native-p2wpkh
        
        let txHex = "0100000002fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac11000000"
        let tx = Tx(Data(hex: txHex))
        XCTAssertEqual(tx.data.hex, txHex)
        let sigMsg = tx.sigMsgV0(hashType: .all, inIdx: 1, scriptCode: .init(Data(hex: "76a9141d0f172a0ecb48aee1be1f2687d2963ae33f71a188ac")), amount: 600_000_000)
        XCTAssertEqual(sigMsg.hex, "0100000096b827c8483d4e9b96712b6713a7b68d6e8003a781feba36c31143470b4efd3752b0a642eea2fb7ae638c36f6252b6750293dbe574a806984b8e4d8548339a3bef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a010000001976a9141d0f172a0ecb48aee1be1f2687d2963ae33f71a188ac0046c32300000000ffffffff863ef3e1a92afbfdb97f31ad0fc7683ee943e9abcf2501590ff8f6551f47e5e51100000001000000")
        let sigHash = hash256(sigMsg) // Message
        XCTAssertEqual(sigHash.hex, "c37af31116d1b27caf68aae9e3ac82f1477929014d5b917657d0eb49478cb670")
        
        let privKey = Data(hex: "619c335025c7f4012e556c2a58b2506e30b8511b53ade95ea316fd8c3286feb9")
        let sig = signECDSA(msg: sigHash, privKey: privKey)
        XCTAssertEqual(sig.hex, "304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee")
    }

    func testTxSignature() {
        // https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#native-p2wpkh

        var tx = Tx(Data(hex: "0100000002fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac11000000"))
        
        let prevOuts = [
            Tx.Out(value: UInt64(625_000_000), scriptPubKeyData: .init(hex: "2103c9f4836b9a4f77fc0d81f7bcb01b7f1b35916864b9476c241ce9fc198bd25432ac")),
            Tx.Out(value: UInt64(0x0046c32300000000).byteSwapped, scriptPubKeyData: .init(hex: "00141d0f172a0ecb48aee1be1f2687d2963ae33f71a1"))
        ]

        let privKey1 = Data(hex: "619c335025c7f4012e556c2a58b2506e30b8511b53ade95ea316fd8c3286feb9")
        let pubKey1 = Data(hex: "025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357")
        tx.signInput(privKey: privKey1, pubKey: pubKey1, hashType: .all, inIdx: 1, prevOuts: prevOuts)

        let privKey0 = Data(hex: "bbc27228ddcb9209d7fd6f36b02f7dfa6252af40bb2f1cbc7a557da8027ff866")
        let pubKey0 = Data(hex: "03c9f4836b9a4f77fc0d81f7bcb01b7f1b35916864b9476c241ce9fc198bd25432")
        tx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .all, inIdx: 0, prevOuts: prevOuts)

        // Matches when grind is off for sign()
        //XCTAssertEqual(signed.data.hex, "01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f00000000494830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc22ede944ccf4ecbab4cc618ef3ed01eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee0121025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee635711000000")
    }
}
