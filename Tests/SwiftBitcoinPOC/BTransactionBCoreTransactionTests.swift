import XCTest
@testable import SwiftBitcoinPOC

final class BTransactionBCoreTransactionTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }

    func testBCoreTransactionConversionRoundTrip() {
        let coreTx = CoreTx.Sample.coinbase1NoAddressDescriptor
        XCTAssertEqual(coreTx, coreTx.toBitcoinTransaction.toBCoreTransaction())
        
        // Testnet!
        let coreTx2 = CoreTx.Sample.segwit1NoDescriptor
        let tx2 = coreTx2.toBitcoinTransaction
        let coreTx2RoundTrip = tx2.toBCoreTransaction(network: .test)
        XCTAssertEqual(coreTx2.vout[0], coreTx2RoundTrip.vout[0])
        XCTAssertEqual(coreTx2, coreTx2RoundTrip)
    }
    
    func testHex() throws {
        let txHex = CoreTx.Sample.coinbase1.hex
        let tx = Transaction(Data(hex: txHex))
        XCTAssertEqual(tx.data.hex, txHex)
        
        // Segwit
        let txHexSegWit = CoreTx.Sample.segwit1.hex
        let txSegWit = Transaction(Data(hex: txHexSegWit))
        XCTAssertEqual(txSegWit.data.hex, txHexSegWit)
    }
    
    func testSizeWeight() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        XCTAssertEqual(tx.size, CoreTx.Sample.coinbase1.size)
        XCTAssertEqual(tx.weight, CoreTx.Sample.coinbase1.weight)
        XCTAssertEqual(tx.virtualSize, CoreTx.Sample.coinbase1.vsize)
        let txSegWit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        XCTAssertEqual(txSegWit.size, txSegWit.size)
        XCTAssertEqual(txSegWit.weight, txSegWit.weight)
        XCTAssertEqual(txSegWit.virtualSize, txSegWit.virtualSize)
    }
    
    func testLockTime() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        XCTAssertEqual(UInt32(tx.locktime.blockHeight!), UInt32(CoreTx.Sample.coinbase1.locktime))
        let txSegWit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        XCTAssertEqual(UInt32(txSegWit.locktime.blockHeight!), UInt32(CoreTx.Sample.segwit1.locktime))
    }
    
    func testVersion() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        XCTAssertEqual(tx.version.rawValue, UInt32(CoreTx.Sample.coinbase1.version))
        let txSegWit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        XCTAssertEqual(txSegWit.version.rawValue, UInt32(CoreTx.Sample.segwit1.version))
    }
    
    func testInputs() throws {
        let bCoreInput = CoreTx.Sample.coinbase1.vin[0]
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        let input = tx.inputs[0]
        let witness = tx.inputs[0].witness
        XCTAssertEqual(input.sequence.rawValue, UInt32(bCoreInput.sequence))
        XCTAssertEqual(input.script.data.hex, bCoreInput.coinbase!)
        XCTAssertEqual(witness?.elements.map(\.hex), bCoreInput.txinwitness)
        
        let segWitInput = CoreTx.Sample.segwit1.vin[0]
        let txSegwit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        let inputSegwit = txSegwit.inputs[0]
        let witnessSegwit = txSegwit.inputs[0].witness
        XCTAssertEqual(inputSegwit.sequence.rawValue, UInt32(segWitInput.sequence))
        XCTAssertEqual(inputSegwit.script.data.hex, segWitInput.scriptSig!.hex)
        XCTAssertEqual(witnessSegwit?.elements.map(\.hex), segWitInput.txinwitness!)
        
    }
    
    func testOutputs() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        let bCoreOutput = CoreTx.Sample.coinbase1.vout[0]
        let output = tx.outputs[0]
        XCTAssertEqual(output.value, Amount(bCoreOutput.value) * 100_000_000)
        XCTAssertEqual(output.script.data.hex, bCoreOutput.scriptPubKey.hex)
        let bCoreOutput2 = CoreTx.Sample.coinbase1.vout[1]
        let output2 = tx.outputs[1]
        XCTAssertEqual(output2.value, Amount(bCoreOutput2.value) * 100_000_000)
        XCTAssertEqual(output2.script.data.hex, bCoreOutput2.scriptPubKey.hex)
    }
    
    func testTxID2() {
        let txID = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"
        let txHex = "0100000001c997a5e56e104102fa209c6a852dd90660a20b2d9c352423edce25857fcd3704000000004847304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901ffffffff0200ca9a3b00000000434104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac00286bee0000000043410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac00000000"
        let tx = Transaction(Data(hex: txHex))
        XCTAssertEqual(tx.data.hex, txHex)
        XCTAssertEqual(tx.data.hex, tx.idData.hex)
        XCTAssertEqual(tx.id, txID)
    }
    
    func testTxID() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        XCTAssertEqual(tx.id, CoreTx.Sample.coinbase1.txid)
        let txSegwit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        XCTAssertEqual(txSegwit.id, CoreTx.Sample.segwit1.txid)
    }
    func testTxHash() throws {
        let tx = Transaction(Data(hex: CoreTx.Sample.coinbase1.hex))
        XCTAssertEqual(tx.witnessID, CoreTx.Sample.coinbase1.hash)
        let txSegwit = Transaction(Data(hex: CoreTx.Sample.segwit1.hex))
        XCTAssertEqual(txSegwit.witnessID, CoreTx.Sample.segwit1.hash)
    }
}