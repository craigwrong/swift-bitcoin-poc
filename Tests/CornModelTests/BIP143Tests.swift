import XCTest
@testable import CornModel

/// https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#native-p2wpkh

final class BIP143Tests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    /// P2SH-P2WPKH
    func testP2SHP2WPKH() {
        var tx = Tx(Data(hex: "0100000001db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d3ceb1a54770100000000feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac92040000"))
        
        // The input comes from a P2SH-P2WPKH witness program:
        let prevOut0 = Tx.Out(value: UInt64(1_000_000_000), scriptPubKeyData: Data(hex: "a9144733f37cf4db86fbc2efed2500b4f4e49f31202387"))
        let redeemScript0 = [Op](Data(hex: "001479091972186c449eb1ded22b78e40d009bdf0089"))
        let privKey0 = Data(hex: "eb696a065ef48a2192da5b28b694f87544b30fae8327c4510137a922f32c6dcf")
        let pubKey0 = Data(hex: "03ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a26873")
        
        tx.signInput(privKeys: [privKey0], pubKeys: [pubKey0], redeemScript: redeemScript0, hashType: .all, inIdx: 0, prevOuts: [prevOut0])
        
        XCTAssertEqual(tx.data.hex, "01000000000101db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d3ceb1a5477010000001716001479091972186c449eb1ded22b78e40d009bdf0089feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac02473044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f8288e5d794d12d482f0220217f36a485cae903c713331d877c1f64677e3622ad4010726870540656fe9dcb012103ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a2687392040000")
    }
}
