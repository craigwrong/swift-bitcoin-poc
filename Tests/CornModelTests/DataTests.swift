import XCTest
import CornModel

final class DataTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }
    
    override class func tearDown() {
        eccStop()
    }
    
    func testTx() {
        let privKey0 = createPrivKey()
        let pubKey0 = getPubKey(privKey: privKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let prevOuts = [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(pubKey: pubKey0)),
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(pubKey: pubKey1))
        ]
        var tx = Transaction(version: .v1, locktime: .disabled,
                    inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
                    outputs: [.init(value: 0, script:ParsedScript.makeNullData(""))]
        )
        tx.sign(privKeys: [privKey0], pubKeys: [pubKey0], sighashType: .singleAnyCanPay, inputIndex: 0, prevOuts: prevOuts)
        var res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        //signed.outputs.removeAll()
        tx.outputs.append(.init(value: 0, script:ParsedScript.makeNullData("")))
        res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        
        tx.inputs.append(Transaction.Input(outpoint: .init(transaction: "", output: 0), sequence: .initial))
        tx.sign(privKeys: [privKey1], pubKeys: [pubKey1], sighashType: .all, inputIndex: 1, prevOuts: prevOuts)
        res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
    }
    
    func testSighashAll() {
        // Some keys
        let privKey0 = createPrivKey()
        let pubKey0 = getPubKey(privKey: privKey0)
        let privKey1 = createPrivKey()
        let pubKey1 = getPubKey(privKey: privKey1)
        let privKey2 = createPrivKey()
        let pubKey2 = getPubKey(privKey: privKey2)
        
        // Some previous outputs
        let prevOuts = [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(pubKey: pubKey0)),
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(pubKey: pubKey1))
        ]
        
        let prevOutsPlus = prevOuts + [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2WKH(pubKey: pubKey2))
        ]
        
        // Our transaction with 2 inputs and 2 outputs
        var tx = Transaction(
            version: .v1,
            locktime: .disabled,
            inputs: [
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
            ],
            outputs: [
                .init(value: 0, script:ParsedScript.makeNullData("")),
                .init(value: 0, script:ParsedScript.makeNullData(""))
            ]
        )
        
        // Sign both inputs
        tx.sign(privKeys: [privKey0], pubKeys: [pubKey0], sighashType: .allAnyCanPay, inputIndex: 0, prevOuts: prevOuts)
        tx.sign(privKeys: [privKey1], pubKeys: [pubKey1], sighashType: .noneAnyCanPay, inputIndex: 1, prevOuts: prevOuts)
        
        // Verify the signed transaction as is
        var res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
        
        // Appending an additional output
        var signedOneMoreOut = tx
        signedOneMoreOut.outputs.append(.init(value: 0, script:ParsedScript.makeNullData("")))
        res = signedOneMoreOut.verify(prevOuts: prevOuts)
        XCTAssertFalse(res)
        
        // Removing one of the outputs
        var signedOutRemoved = tx
        signedOutRemoved.outputs.remove(at: 0)
        res = signedOutRemoved.verify(prevOuts: prevOuts)
        XCTAssertFalse(res)
        
        // Appending an additional input
        var signedOneMoreIn = tx
        signedOneMoreIn.inputs.append(.init(outpoint: .init(transaction: "", output: 0), sequence: .initial))
        signedOneMoreIn.sign(privKeys: [privKey2], pubKeys: [pubKey2], sighashType: .noneAnyCanPay, inputIndex: 2, prevOuts: prevOutsPlus)
        res = signedOneMoreIn.verify(prevOuts: prevOutsPlus)
        XCTAssert(res)
        
        // Removing the last one of the inputs
        var signedInRemoved = tx
        signedInRemoved.inputs.remove(at: 1)
        res = signedInRemoved.verify(prevOuts: [prevOuts[0]])
        XCTAssert(res)
    }
    
    func testMultipleInputTypes() {
        let privKeys = (0...10).map { _ in createPrivKey() }
        let pubKeys = privKeys.map { getPubKey(privKey: $0) }
        
        let redeemScript2 = ParsedScript([
            .constant(2),
            .pushBytes(pubKeys[3]),
            .pushBytes(pubKeys[2]),
            .constant(2),
            .checkMultiSig
        ])

        let redeemScript4 = ParsedScript.makeP2WKH(pubKey: pubKeys[4])
        let redeemScript5 = ParsedScript([
            .constant(2),
            .pushBytes(pubKeys[6]),
            .pushBytes(pubKeys[5]),
            .constant(2),
            .checkMultiSig
        ], version: .witnessV0)
        let redeemScriptV06 = ParsedScript([
            .constant(2),
            .pushBytes(pubKeys[7]),
            .pushBytes(pubKeys[6]),
            .constant(2),
            .checkMultiSig
        ], version: .witnessV0)
        let redeemScript6 = ParsedScript.makeP2WSH(redeemScriptV0: redeemScriptV06)
        
        let outputKey7 = getOutputKey(privKey: privKeys[7])

        // Sprevious outputs
        let prevOuts = [
            // p2pk
            Transaction.Output(value: 0, script:ParsedScript.makeP2PK(pubKey: pubKeys[0])),
            
            // p2pkh
            Transaction.Output(value: 0, script:ParsedScript.makeP2PKH(pubKey: pubKeys[1])),
            
            // p2sh
            Transaction.Output( value: 0,
                script: ParsedScript.makeP2SH(redeemScript: redeemScript2)
            ),
            
            // p2wkh
            Transaction.Output(value: 0, script:ParsedScript.makeP2WKH(pubKey: pubKeys[3])),
            
            // p2sh-p2wkh
            Transaction.Output(value: 0,
                script: ParsedScript.makeP2SH(redeemScript: redeemScript4)
            ),

            // p2wsh
            Transaction.Output(value: 0,
                script: ParsedScript.makeP2WSH(redeemScriptV0: redeemScript5)
            ),

            // p2sh-p2wsh
            Transaction.Output(value: 0,
                script: ParsedScript.makeP2SH(redeemScript: redeemScript6)
            ),

            // p2tr (key path)
            Transaction.Output(value: 0,
                script: ParsedScript.makeP2TR(outputKey: outputKey7)
            ),
            
            // legacy multisig
            Transaction.Output(value: 0,
                script: .init([
                    .constant(2),
                    .pushBytes(pubKeys[9]),
                    .pushBytes(pubKeys[8]),
                    .constant(2),
                    .checkMultiSig
                ])
            )
        ]
        
        // Our transaction with 6 inputs and 2 outputs
        var tx = Transaction(
            version: .v1,
            locktime: .disabled,
            inputs: [
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
                .init(outpoint: .init(transaction: "", output: 0), sequence: .initial),
            ],
            outputs: [
                .init(value: 0, script:ParsedScript.makeNullData("")),
                .init(value: 0, script:ParsedScript.makeNullData(""))
            ]
        )
        tx.sign(privKeys: [privKeys[0]], sighashType: .all, inputIndex: 0, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[1]], pubKeys: [pubKeys[1]], sighashType: .all, inputIndex: 1, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[2], privKeys[3]], redeemScript: redeemScript2, sighashType: .all, inputIndex: 2, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[3]], pubKeys: [pubKeys[3]], sighashType: .all, inputIndex: 3, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[4]], pubKeys: [pubKeys[4]], redeemScript: redeemScript4, sighashType: .all, inputIndex: 4, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[5], privKeys[6]], redeemScriptV0: redeemScript5, sighashType: .all, inputIndex: 5, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[6], privKeys[7]], redeemScript: redeemScript6, redeemScriptV0: redeemScriptV06, sighashType: .all, inputIndex: 6, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[7]], inputIndex: 7, prevOuts: prevOuts)
        tx.sign(privKeys: [privKeys[8], privKeys[9]], sighashType: .all, inputIndex: 8, prevOuts: prevOuts)
        
        let res = tx.verify(prevOuts: prevOuts)
        XCTAssert(res)
    }
}
