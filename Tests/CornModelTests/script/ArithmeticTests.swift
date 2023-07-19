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
        XCTAssertNoThrow(try script.run(&stack)) // Zero at the end of script execution
        XCTAssertEqual(stack, [Data([UInt8(3 | 0x80)])])
        
        let number = withUnsafeBytes(of: Int16(128)) { Data($0) }
        script = ParsedScript([.pushBytes(number), .constant(1), .negate, .add])
        stack = .init()
        XCTAssertNoThrow(try script.run(&stack))
        XCTAssertEqual(stack, [Data([127])])
    }
}
