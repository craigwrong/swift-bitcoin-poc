import XCTest
@testable import CornModel

final class TapscriptPlaygroundTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }
    
    override class func tearDown() {
        eccStop()
    }
    
    func testTapscriptSpend() {
        let privKey = createPrivKey()
        let scriptTree = ScriptTree.branch(.leaf(0xc0, [.success(80)]), .leaf(0xc0, [.checkSigVerify]))
        
        let outputKey = scriptTree.getOutputKey(privKey: privKey)
        
        let prevOuts = [Tx.Out(value: 100, scriptPubKey: makeP2TR(outputKey: outputKey))]
        
        var tx = Tx(version: .v1, lockTime: 0,
            ins: [.init(txID: "", outIdx: 0, sequence: 0)],
            outs: [.init(value: 50, scriptPubKey: makeNullData(""))])
        
        tx.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 1, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        let result = tx.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }

    func testOpCheckSigAdd() {
        let privKey = createPrivKey()
        let scriptTree = ScriptTree.branch(.leaf(0xc0, [.success(80)]), .leaf(0xc0, [.checkSig, .pushBytes(getInternalKey(privKey: privKey)), .checkSigAdd, .constant(1), .equal]))
        let outputKey = scriptTree.getOutputKey(privKey: privKey)
        
        let prevOuts = [Tx.Out(value: 100, scriptPubKey: makeP2TR(outputKey: outputKey))]
        
        var tx = Tx(version: .v1, lockTime: 0,
            ins: [.init(txID: "", outIdx: 0, sequence: 0)],
            outs: [.init(value: 50, scriptPubKey: makeNullData(""))])
        
        tx.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 1, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        tx.ins[0].witness?.insert(Data(), at: 0)
        let result = tx.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }

    func testVector1() {
        var tx = Tx(Data(hex: "0100000001d4bde0bdf078643b0663e4b666991a0e49c5320ec3a5b803ced4c66d149dfaf37001000000a5db6863012798ac0000000000160014daf166b6fedce282c529a52b0aa76ad36f21ab0fdf87e243"))
        let prevOuts = [
            Tx.Out(Data(hex: "d99fa50100000000225120970d8939d38761651bceca37e9eaa68f4b1dbcd995084d91fbb5ea7d47ee29bd"))
        ]
        tx.ins[0].witness = [
            Data(hex: "d060a7b313e9a8eedc795815cca42a4cbe59bab2a47a0f777a7907eb13be7a29d0ab305cd375d80984a9f6a8c510fc27d1e094febae8239a9bebbdd69c964fd8"),
            Data(hex: "0051ba"),
            Data(hex: "c0c59219fcbc494c3fecab3416442367fb60fbf30f8a182ca40150f49cfd4aecd702325f2ccdf3eb72a08e2293762d885896ccc22723a7c16d156317f370375669e3b4b363deb91f58e8d08d340506743f4dc982d99fd785b05eddc5135869ca0ae6f60e18146ca9ab3fd7f519021439fb79e07914b6465068c1f2d9640a021e560ffb05d4b2de3317ae564f6de7d6be15c72071629550ff907275aa8961c05d9baf8c6d278e88bdb7edc443ae5a12011758d17d24d40a1376a2ee0692c7b20b166507a8b43e7d9fe1597de3e6f095781e6dfca87dd9cd95bc5c8f5fdd1c9465ca88747ee6b2edfbca60c0595edcf500a191c4034b93186bb16dd728ed855dc9485549749a7e374c4112f0b0ad1bee7c4befb5903f41b13fc9b0216a64aa3716cdc3e4fe976b8716a2f9cb95262235d0522de25d89a7683c03120ea12162dee5a60e7c7ee67ad3583ce382fb3590d6d5de7e16ce1d62905f187d9f344cdbf85b82c6e6f36014ee3c2f39ceb9313e8e4cac4a983eadad288cea5e86567dc007c6d58a06a38ebb0e236f0b2886589c34da8181b4ca2d0e7e08ac005d46d1e7acf748440cd41f35b4568a2e4f567eb540a31fd27507f31de2a39f8ceadda91474d6792eaa289e892a6c703077d31b00eea1227d2ffe54751c7576844e9bd2f475d154d3834790a9df08092d5046d76f8652651aaa68f8380952662d108e12ff14a0a98278e73b83cbdf9925e224685a77121513d0c1cfd7802cc7f8d650f214edebc8")
            ]
            let result = tx.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }
    
    func testVectors() {
        for testCase in coreTestAssets {
            let unsigned = Tx(Data(hex: testCase.tx))
            let prevOuts = testCase.prevOuts.map { Tx.Out(Data(hex: $0)) }
            let inIdx = testCase.inIdx
            var tx = unsigned
            tx.ins[inIdx].scriptSig = [Op](Data(hex: testCase.success.scriptSig))
            tx.ins[inIdx].witness = testCase.success.witness.map { Data(hex: $0) }
            XCTAssertNoThrow(try tx.verify(inIdx: inIdx, prevOuts: prevOuts))
            if let failure = testCase.failure {
                var failTx = unsigned
                failTx.ins[inIdx].scriptSig = [Op](Data(hex: failure.scriptSig))
                failTx.ins[inIdx].witness = failure.witness.map { Data(hex: $0) }
                XCTAssertThrowsError(try failTx.verify(inIdx: inIdx, prevOuts: prevOuts))
            }
        }
    }
}
