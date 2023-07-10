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
        
        let prevOuts = [Transaction.Output(value: 100, script: ParsedScript.makeP2TR(outputKey: outputKey))]
        
        var tx = Transaction(version: .v1, locktime: .disabled,
            inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
            outputs: [.init(value: 50, script: ParsedScript.makeNullData(""))])
        
        tx.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 1, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        let result = tx.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }

    func testOpCheckSigAdd() {
        let privKey = createPrivKey()
        let scriptTree = ScriptTree.branch(.leaf(0xc0, [.success(80)]), .leaf(0xc0, [.checkSig, .pushBytes(getInternalKey(privKey: privKey)), .checkSigAdd, .constant(1), .equal]))
        let outputKey = scriptTree.getOutputKey(privKey: privKey)
        
        let prevOuts = [Transaction.Output(value: 100, script: ParsedScript.makeP2TR(outputKey: outputKey))]
        
        let tx = Transaction(version: .v1, locktime: .disabled,
            inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
            outputs: [.init(value: 50, script: ParsedScript.makeNullData(""))])
        
        var tx0 = tx
        tx0.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 0, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        tx0.inputs[0].witness = .init([Data.zero] + tx0.inputs[0].witness!.elements)
        var result = tx0.verify(prevOuts: prevOuts)

        var tx1 = tx
        tx1.sign(privKeys: [privKey], scriptTree: scriptTree, leafIdx: 1, taprootAnnex: .none, inIdx: 0, prevOuts: prevOuts)
        tx1.inputs[0].witness = .init([Data.zero] + tx1.inputs[0].witness!.elements)
        result = tx1.verify(prevOuts: prevOuts)
        XCTAssert(result)
    }
    
    func testVectors() {
        for testCase in coreTestAssets {
            let unsigned = Transaction(Data(hex: testCase.tx))
            let prevOuts = testCase.prevOuts.map { Transaction.Output(Data(hex: $0)) }
            let inIdx = testCase.inIdx
            var tx = unsigned
            tx.inputs[inIdx].script = .init(Data(hex: testCase.success.scriptSig))
            tx.inputs[inIdx].witness = .init(testCase.success.witness.map { Data(hex: $0) })
            XCTAssertNoThrow(try tx.verify(inIdx: inIdx, prevOuts: prevOuts))
            if let failure = testCase.failure {
                var failTx = unsigned
                failTx.inputs[inIdx].script = .init(Data(hex: failure.scriptSig))
                failTx.inputs[inIdx].witness = .init(failure.witness.map { Data(hex: $0) })
                XCTAssertThrowsError(try failTx.verify(inIdx: inIdx, prevOuts: prevOuts))
            }
        }
    }
}
