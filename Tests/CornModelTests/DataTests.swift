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
        let secretKey0 = createSecretKey()
        let publicKey0 = getPublicKey(secretKey: secretKey0)
        let secretKey1 = createSecretKey()
        let publicKey1 = getPublicKey(secretKey: secretKey1)
        let previousOutputs = [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(publicKey: publicKey0)),
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(publicKey: publicKey1))
        ]
        var tx = Transaction(version: .v1, locktime: .disabled,
                    inputs: [.init(outpoint: .init(transaction: "", output: 0), sequence: .initial)],
                    outputs: [.init(value: 0, script:ParsedScript.makeNullData(""))]
        )
        tx.sign(secretKeys: [secretKey0], publicKeys: [publicKey0], sighashType: .singleAnyCanPay, inputIndex: 0, previousOutputs: previousOutputs)
        var res = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(res)
        //signed.outputs.removeAll()
        tx.outputs.append(.init(value: 0, script:ParsedScript.makeNullData("")))
        res = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(res)
        
        tx.inputs.append(Transaction.Input(outpoint: .init(transaction: "", output: 0), sequence: .initial))
        tx.sign(secretKeys: [secretKey1], publicKeys: [publicKey1], sighashType: .all, inputIndex: 1, previousOutputs: previousOutputs)
        res = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(res)
    }
    
    func testSighashAll() {
        // Some keys
        let secretKey0 = createSecretKey()
        let publicKey0 = getPublicKey(secretKey: secretKey0)
        let secretKey1 = createSecretKey()
        let publicKey1 = getPublicKey(secretKey: secretKey1)
        let secretKey2 = createSecretKey()
        let publicKey2 = getPublicKey(secretKey: secretKey2)
        
        // Some previous outputs
        let previousOutputs = [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(publicKey: publicKey0)),
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2PKH(publicKey: publicKey1))
        ]
        
        let previousOutputsPlus = previousOutputs + [
            Transaction.Output(value: 0,
                   script: ParsedScript.makeP2WKH(publicKey: publicKey2))
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
        tx.sign(secretKeys: [secretKey0], publicKeys: [publicKey0], sighashType: .allAnyCanPay, inputIndex: 0, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKey1], publicKeys: [publicKey1], sighashType: .noneAnyCanPay, inputIndex: 1, previousOutputs: previousOutputs)
        
        // Verify the signed transaction as is
        var res = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(res)
        
        // Appending an additional output
        var signedOneMoreOut = tx
        signedOneMoreOut.outputs.append(.init(value: 0, script:ParsedScript.makeNullData("")))
        res = signedOneMoreOut.verify(previousOutputs: previousOutputs)
        XCTAssertFalse(res)
        
        // Removing one of the outputs
        var signedOutRemoved = tx
        signedOutRemoved.outputs.remove(at: 0)
        res = signedOutRemoved.verify(previousOutputs: previousOutputs)
        XCTAssertFalse(res)
        
        // Appending an additional input
        var signedOneMoreIn = tx
        signedOneMoreIn.inputs.append(.init(outpoint: .init(transaction: "", output: 0), sequence: .initial))
        signedOneMoreIn.sign(secretKeys: [secretKey2], publicKeys: [publicKey2], sighashType: .noneAnyCanPay, inputIndex: 2, previousOutputs: previousOutputsPlus)
        res = signedOneMoreIn.verify(previousOutputs: previousOutputsPlus)
        XCTAssert(res)
        
        // Removing the last one of the inputs
        var signedInRemoved = tx
        signedInRemoved.inputs.remove(at: 1)
        res = signedInRemoved.verify(previousOutputs: [previousOutputs[0]])
        XCTAssert(res)
    }
    
    func testMultipleInputTypes() {
        let secretKeys = (0...10).map { _ in createSecretKey() }
        let publicKeys = secretKeys.map { getPublicKey(secretKey: $0) }
        
        let redeemScript2 = ParsedScript([
            .constant(2),
            .pushBytes(publicKeys[3]),
            .pushBytes(publicKeys[2]),
            .constant(2),
            .checkMultiSig
        ])

        let redeemScript4 = ParsedScript.makeP2WKH(publicKey: publicKeys[4])
        let redeemScript5 = ParsedScript([
            .constant(2),
            .pushBytes(publicKeys[6]),
            .pushBytes(publicKeys[5]),
            .constant(2),
            .checkMultiSig
        ], version: .witnessV0)
        let redeemScriptV06 = ParsedScript([
            .constant(2),
            .pushBytes(publicKeys[7]),
            .pushBytes(publicKeys[6]),
            .constant(2),
            .checkMultiSig
        ], version: .witnessV0)
        let redeemScript6 = ParsedScript.makeP2WSH(redeemScriptV0: redeemScriptV06)
        
        let outputKey7 = getOutputKey(secretKey: secretKeys[7])

        // Sprevious outputs
        let previousOutputs = [
            // p2pk
            Transaction.Output(value: 0, script:ParsedScript.makeP2PK(publicKey: publicKeys[0])),
            
            // p2pkh
            Transaction.Output(value: 0, script:ParsedScript.makeP2PKH(publicKey: publicKeys[1])),
            
            // p2sh
            Transaction.Output( value: 0,
                script: ParsedScript.makeP2SH(redeemScript: redeemScript2)
            ),
            
            // p2wkh
            Transaction.Output(value: 0, script:ParsedScript.makeP2WKH(publicKey: publicKeys[3])),
            
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
                    .pushBytes(publicKeys[9]),
                    .pushBytes(publicKeys[8]),
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
        tx.sign(secretKeys: [secretKeys[0]], sighashType: .all, inputIndex: 0, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[1]], publicKeys: [publicKeys[1]], sighashType: .all, inputIndex: 1, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[2], secretKeys[3]], redeemScript: redeemScript2, sighashType: .all, inputIndex: 2, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[3]], publicKeys: [publicKeys[3]], sighashType: .all, inputIndex: 3, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[4]], publicKeys: [publicKeys[4]], redeemScript: redeemScript4, sighashType: .all, inputIndex: 4, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[5], secretKeys[6]], redeemScriptV0: redeemScript5, sighashType: .all, inputIndex: 5, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[6], secretKeys[7]], redeemScript: redeemScript6, redeemScriptV0: redeemScriptV06, sighashType: .all, inputIndex: 6, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[7]], inputIndex: 7, previousOutputs: previousOutputs)
        tx.sign(secretKeys: [secretKeys[8], secretKeys[9]], sighashType: .all, inputIndex: 8, previousOutputs: previousOutputs)
        
        let res = tx.verify(previousOutputs: previousOutputs)
        XCTAssert(res)
    }
}
