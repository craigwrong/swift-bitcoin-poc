import XCTest
import CornModel

final class OpSwapTests: XCTestCase {
    
    func testNormalOperation() {
        var script = ParsedScript([.constant(1), .constant(2), .swap])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [.init([2]), .init([1])])
    }
}
