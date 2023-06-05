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
        
        let internalKey = getInternalKey(privKey: privKey)
        
        let ops0: [ScriptV1.Op] = [.success(80)]
        let ops1: [ScriptV1.Op] = [.checkSigVerify]
        
        let scriptTree = ScriptTree.branch(.leaf(0xc0, ops0), .leaf(0xc0, ops1))
        let (treeInfo, merkleRoot) = scriptTree.calcMerkleRoot()

        let outputKey = getOutputKey(privKey: privKey, merkleRoot: merkleRoot)
        
        let prevOuts = [Tx.Out(value: 100, scriptPubKey: .makeP2TR(outputKey: outputKey))]
        
        var tx = Tx(version: .v1, lockTime: 0,
            ins: [.init(txID: "", outIdx: 0, sequence: 0)],
            outs: [.init(value: 50, scriptPubKey: .makeNullData(""))])

        var tapscript0 = ScriptV1(ops0)
        var tapscript1 = ScriptV1(ops1)
        var control = computeControlBlock(internalPubKey: internalKey, leafInfo: treeInfo[1], merkleRoot: merkleRoot)
        
        tx.signInput(privKeys: [privKey], tapscript: tapscript1, merkleRoot: merkleRoot, controlBlock: control, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        let result = tx.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }
}
