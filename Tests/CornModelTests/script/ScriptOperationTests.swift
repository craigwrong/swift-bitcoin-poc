import XCTest
import CornModel

final class ScriptOperationTests: XCTestCase {
    
    func testArithmeticOps() {

        let vectors = [
            ([1], [ScriptOperation.zeroNotEqual], [1]),
            ([0], [.zeroNotEqual, .constant(1)], [0, 1]),
            ([0], [.oneAdd], [1]),
            ([1], [.oneAdd], [2]),
            ([-1], [.oneAdd, .constant(1)], [0, 1]),
            ([1], [.negate, .oneAdd, .constant(1)], [0, 1]),
            ([], [.oneNegate], [-1]),
            ([0], [.oneSub], [-1]),
            ([1], [.negate, .oneSub], [-2]),
            ([1], [.oneSub, .constant(1)], [0, 1]),
            ([1, 2], [.twoDrop], []),
            ([1, 2], [.twoDup], [1, 2, 1, 2]),
            ([2, 0, 1], [.twoDup], [2, 0, 1, 0, 1]),
            ([1, 2, 3, 4], [.twoOver], [1, 2, 3, 4, 1, 2]),
            ([1, 0, 3, 4], [.twoOver, .constant(1)], [1, 0, 3, 4, 1, 0, 1]),
            ([1, 2, 3, 4, 5, 6], [.twoRot], [3, 4, 5, 6, 1, 2]),
            ([1, 2, 3, 4], [.twoSwap], [3, 4, 1, 2]),
            ([1, 2, 3], [.threeDup], [1, 2, 3, 1, 2, 3]),
            ([-1], [.abs], [1]),
            ([0], [.abs, .constant(1)], [0, 1]),
            ([1], [.abs], [1]),
            ([1, 2], [.add], [3]),
            ([1, 2], [.add], [3]),
            ([1, 1], [.boolAnd], [1]),
            ([0, 1], [.boolAnd, .constant(1)], [0, 1]),
            ([1, 0], [.boolAnd, .constant(1)], [0, 1]),
            ([0, 0], [.boolAnd, .constant(1)], [0, 1]),
            ([1, 0], [.boolOr], [1]),
            ([0, 1], [.boolOr], [1]),
            ([1, 1], [.boolOr], [1]),
            ([0, 0], [.boolOr, .constant(1)], [0, 1]),
            ([0, 0, 0], [.depth], [0, 0, 0, 3]),
            ([], [.depth, .zero, .equal], [1]),
            ([1], [.depth, .equal], [1]),
            ([1, 2], [.drop], [1]),
            ([1], [.dup], [1, 1]),
            ([1, 2], [.swap], [2, 1]),
            ([0, 0], [.equal], [1]),
            ([-1, -1], [.equal], [1]),
            ([1, 1], [.equal], [1]),
            ([0xffffffff, 0xffffffff], [.equal], [1]),
            ([0, 1], [.equal, .constant(1)], [0, 1]),
            ([1], [.toAltStack, .zero, .fromAltStack], [0, 1]),
        ]
        
        for v in vectors {
            var stack = [Data].withConstants(v.0)
            XCTAssertNoThrow(try ParsedScript(v.1).run(&stack))
            XCTAssertEqual(stack, .withConstants(v.2))
        }
    }
}
