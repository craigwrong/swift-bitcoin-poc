import XCTest
@testable import CornModel

final class ArithmeticTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }
    
    func testAddNegative() {
        var script = ParsedScript([.constant(8), .constant(11), .negate, .add])
        var stack = [Data]()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inIdx: -1, prevOuts: [])) // Zero at the end of script execution
        XCTAssertEqual(stack, [Data([UInt8(bitPattern: -3)])])
        
        let number = withUnsafeBytes(of: Int16(128)) { Data($0) }
        script = ParsedScript([.pushBytes(number), .constant(1), .negate, .add])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack, transaction: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([127])])
    }
}
