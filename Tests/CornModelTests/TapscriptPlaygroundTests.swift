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
        
        var tx = Tx(version: .v1, locktime: .disabled,
            ins: [.init(txID: "", outIdx: 0, sequence: .initial)],
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
        
        let tx = Tx(version: .v1, locktime: .disabled,
            ins: [.init(txID: "", outIdx: 0, sequence: .initial)],
            outs: [.init(value: 50, scriptPubKey: makeNullData(""))])
        
        var tx0 = tx
        tx0.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 0, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        tx0.ins[0].witness?.insert(Data(), at: 0)
        var result = tx0.verify(prevOuts: prevOuts)        

        var tx1 = tx
        tx1.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 1, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        tx1.ins[0].witness?.insert(Data(), at: 0)
        result = tx1.verify(prevOuts: prevOuts)
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
