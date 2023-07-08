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
