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
        let secretKey = createSecretKey()
        let scriptTree = ScriptTree.branch(.leaf(0xc0, ParsedScript([.success(80)], version: .witnessV1).data), .leaf(0xc0, ParsedScript([.checkSigVerify], version: .witnessV1).data))
        
        let outputKey = scriptTree.getOutputKey(secretKey: secretKey)
        
        let previousOutputs = [Transaction.Output(value: 100, script: ParsedScript.makeP2TR(outputKey: outputKey))]
        
        var tx = Transaction(version: .v1, locktime: .disabled,
            inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
            outputs: [.init(value: 50, script: ParsedScript.makeNullData(""))])
        
        tx.sign(secretKeys: [secretKey], scriptTree: scriptTree, leafIndex: 1, taprootAnnex: .none, inputIndex: 0, previousOutputs: previousOutputs)
        let result = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(result)
    }

    func testOpCheckSigAdd() {
        let secretKey = createSecretKey()
        let secretKey2 = createSecretKey()
        let scriptTree = ScriptTree.branch(
            .leaf(0xc0, ParsedScript([.success(80)], version: .witnessV1).data),
            .leaf(0xc0, ParsedScript([
                .checkSig,
                .pushBytes(getInternalKey(secretKey: secretKey2)),
                .checkSigAdd,
                .constant(2),
                .equal], version: .witnessV1).data))
        let outputKey = scriptTree.getOutputKey(secretKey: secretKey)
        
        let previousOutputs = [Transaction.Output(value: 100, script: ParsedScript.makeP2TR(outputKey: outputKey))]
        
        let tx = Transaction(version: .v1, locktime: .disabled,
            inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
            outputs: [.init(value: 50, script: ParsedScript.makeNullData(""))])
        
        // OP_SUCCESS branch
        var tx0 = tx
        tx0.sign(secretKeys: [secretKey], scriptTree: scriptTree, leafIndex: 0, taprootAnnex: .none, inputIndex: 0, previousOutputs: previousOutputs)
        var newElements = tx0.inputs[0].witness!.elements
        newElements.removeFirst(2) // No need for signature and key since there is no signature checking, only OP_SUCCESS
        tx0.inputs[0].witness = .init(newElements)
        var result = tx0.verify(previousOutputs: previousOutputs)
        XCTAssert(result)

        // CHECKSIGADD 2 of 2 branch
        // Second keypair (validated by checksigadd)
        var tx2 = tx
        tx2.sign(secretKeys: [secretKey2], scriptTree: scriptTree, leafIndex: 1, taprootAnnex: .none, inputIndex: 0, previousOutputs: previousOutputs)
        // First keypair (validated by checksig)
        var tx1 = tx
        tx1.sign(secretKeys: [secretKey], scriptTree: scriptTree, leafIndex: 1, taprootAnnex: .none, inputIndex: 0, previousOutputs: previousOutputs)
        tx1.inputs[0].witness = .init([tx2.inputs[0].witness!.elements[0]] + tx1.inputs[0].witness!.elements)
        result = tx1.verify(previousOutputs: previousOutputs)
        XCTAssert(result)
        
        // Keypath spending
        var tx3 = tx
        tx3.sign(secretKeys: [secretKey], scriptTree: scriptTree, taprootAnnex: .none, inputIndex: 0, previousOutputs: previousOutputs)
        result = tx3.verify(previousOutputs: previousOutputs)
        XCTAssert(result)
    }
    
    func testVectors() {
        for testCase in coreTestAssets {
            let unsigned = Transaction(Data(hex: testCase.tx))
            let previousOutputs = testCase.previousOutputs.map { Transaction.Output(Data(hex: $0)) }
            let inputIndex = testCase.inputIndex
            var tx = unsigned
            tx.inputs[inputIndex].script = .init(Data(hex: testCase.success.scriptSig))
            tx.inputs[inputIndex].witness = .init(testCase.success.witness.map { Data(hex: $0) })
            XCTAssertNoThrow(try tx.verify(inputIndex: inputIndex, previousOutputs: previousOutputs))
            if let failure = testCase.failure {
                var failTx = unsigned
                failTx.inputs[inputIndex].script = .init(Data(hex: failure.scriptSig))
                failTx.inputs[inputIndex].witness = .init(failure.witness.map { Data(hex: $0) })
                XCTAssertThrowsError(try failTx.verify(inputIndex: inputIndex, previousOutputs: previousOutputs))
            }
        }
    }
}
