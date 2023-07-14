import XCTest
import CornModel

final class OpDepthTests: XCTestCase {
    
    func testNormalOperation() {
        var script = ParsedScript([.zero, .zero, .zero, .depth])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data(), Data(), Data(), Data([3])])

        script = ParsedScript([.depth, .zero, .equal])
        stack = []
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([1])])

        script = ParsedScript([.constant(1), .depth, .equal])
        stack = []
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([1])])
    }
}
