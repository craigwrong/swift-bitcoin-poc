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
}
