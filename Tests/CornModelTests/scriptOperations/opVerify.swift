import XCTest
import CornModel

final class OpVerifyTests: XCTestCase {
    
    func testNormalOperation() {
        var script = ParsedScript([.constant(1), .constant(2), .twoDrop])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [])
    }
}
