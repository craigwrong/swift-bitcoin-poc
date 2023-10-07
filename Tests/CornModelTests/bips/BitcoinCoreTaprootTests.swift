import XCTest
@testable import CornModel

final class BitcoinCoreTaprootTests: XCTestCase {

    override class func setUp() {
        eccStart()
    }
    
    override class func tearDown() {
        eccStop()
    }
    
    func testVectors() {
        for testCase in coreTestAssets {
            let unsigned = Transaction(Data(hex: testCase.tx))
            let previousOutputs = testCase.previousOutputs.map { Output(Data(hex: $0)) }
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
