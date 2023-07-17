import XCTest
import Foundation
import CornModel

final class OpAddTests: XCTestCase {
    
    func testNormalOperation() {
        var script = ParsedScript([.constant(1), .constant(2), .add])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inputIndex: -1, previousOutputs: []))
        XCTAssertEqual(stack, [Data([3])])
    }
}
