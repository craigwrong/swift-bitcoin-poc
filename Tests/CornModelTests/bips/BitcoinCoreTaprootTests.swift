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
