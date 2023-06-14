import XCTest
@testable import CornModel

final class OpIfTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }
    
    override class func tearDown() {
        eccStop()
    }
    
    func testIf() {
        
        // If branch
        //var script = [Op.constant(1), .if, .constant(2), .else, .constant(3), .endIf]
        var script = [Op.constant(1), .if, .constant(2), .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // If branch (not activated)
        script = [.zero, .if, .constant(2), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
    }
    
    func testNotIf() {
        
        // Not-if (activated)
        var script = [Op.zero, .notIf, .constant(2), .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // Not-if (not activated)
        script = [.constant(1), .notIf, .constant(2), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
    }

    func testElse() {
        
        // If branch
        //var script = [Op.constant(1), .if, .constant(2), .else, .constant(3), .endIf]
        var script = [Op.constant(1), .if, .constant(2), .else, .constant(3), .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // If branch (not activated), else branch (activated)
        script = [.zero, .if, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // Not-If branch (activated), else branch (not activated)
        script = [.zero, .notIf, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // Not-If branch (not activated), else branch (activated)
        script = [.constant(1), .notIf, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
    }

    func testNestedIf() {
        
        // If branch
        var script = [Op.constant(1), .if, .constant(1), .if, .constant(2), .endIf, .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // 2 level nesting
        script = [.constant(1), .if, .constant(1), .if, .constant(1), .if, .constant(2), .endIf, .endIf, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
    }

    func testNestedElse() {
        // Inner else
        var script = [Op.constant(1), .if, .zero, .if, .constant(2), .else, .constant(3) , .endIf, .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // 2 level nesting, inner else
        script = [.constant(1), .if, .constant(1), .if, .zero, .if, .constant(2), .else, .constant(3) , .endIf, .endIf, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // 1 level nesting, outer else
        script = [.zero, .if, .constant(1), .if, .constant(2), .endIf, .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // 2 level nesting, outer else
        script = [.zero, .if, .constant(1), .if, .constant(1), .if, .constant(2), .endIf, .endIf, .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // 2 level nesting, middle else
        script = [.constant(1), .if, .zero, .if, .constant(1), .if, .constant(2), .endIf, .else, .constant(3), .endIf, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // 2 level nesting, alternate 1
        script = [.zero, .if, .constant(1), .if, .constant(1), .if, .constant(2), .else, .constant(3), .endIf, .else, .constant(4), .endIf, .else, .constant(5), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([5])])

        // alternate 2
        script = [.constant(1), .if, .zero, .if, .constant(1), .if, .constant(2), .else, .constant(3), .endIf, .else, .constant(4), .endIf, .else, .constant(5), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([4])])
        
        // alternate 2
        script = [.constant(1), .if, .constant(1), .if, .zero, .if, .constant(2), .else, .constant(3), .endIf, .else, .constant(4), .endIf, .else, .constant(5), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
    }

    func testEmptyBranches() {
        // Empty if branch
        var script = [Op.constant(1), .if, .else, .constant(3), .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
        
        // Empty if branch (negative)
        script = [.zero, .if, .else, .constant(3), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([3])])
        
        // Empty else branch (activated)
        script = [.zero, .if, .constant(2), .else, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
        
        // Empty else branch (not activated)
        script = [.constant(1), .if, .constant(2), .else, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])
        
        // Empty branches
        script = [.constant(1), .if, .else, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
        
        // Empty branches (negative)
        script = [.zero, .if, .else, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [])
    }

    func testMinimalif() {
        // True-ish value
        var script = [Op.constant(2), .if, .constant(2), .else, .constant(3), .endIf]
        var stack = [Data]()
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))

        // Falsish value
        script = [.pushBytes(Data([0])), .if, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))

        // Falsish value not-if
        script = [.pushBytes(Data([0])), .notIf, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))

        // true-ish value not-if
        script = [.constant(2), .notIf, .constant(2), .else, .constant(3), .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
    }

    func testIfMalformed() {
        // Missing endif (does not check)
        var script = [Op.constant(1), .if, .constant(1), .if, .constant(2), .endIf]
        var stack = [Data]()
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])

        // Too many endifs
        script = [.constant(1), .if, .constant(2), .endIf, .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        
        script = [.zero, .if, .constant(2), .endIf, .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        
        // Too many else's (else branch not evaluated)
        script = [.constant(1), .if, .constant(2), .else, .constant(3), .else, .constant(4), .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        XCTAssertEqual(stack, [Data([2])])

        // Too many else's (else branch evaluated)
        script = [.zero, .if, .constant(2), .else, .constant(3), .else, .constant(4), .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
        
        // interlaceed (not detected)
        script = [
            .constant(1), .if, .constant(1), .if, .constant(2), .else, .constant(3), .else, .constant(4), .endIf, .endIf]
        stack = []
        XCTAssertNoThrow(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))

        script = [
            .zero, .if, .constant(1), .if, .constant(2), .else, .constant(3), .else, .constant(4), .endIf, .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))

        script = [
            .constant(1), .if, .zero, .if, .constant(2), .else, .constant(3), .else, .constant(4), .endIf, .endIf]
        stack = []
        XCTAssertThrowsError(try runScript(script, stack: &stack, tx: .empty, inIdx: -1, prevOuts: []))
    }
}
