import XCTest
@testable import CornModel

final class BCoreTransactionTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }

    func testNonWitnessTx() throws {
        let json = """
{"txid":"9c218eb2aef4450b1dec636b1c4c11f6b42e1b56074f36fc5998537457037ec1","hash":"d8cb1301bda5ccaf80be773835c120ae04b25a35bd319d4c2e7f2cba6c70e6dd","version":2,"size":170,"vsize":143,"weight":572,"locktime":0,"vin":[{"coinbase":"5200","txinwitness":["0000000000000000000000000000000000000000000000000000000000000000"],"sequence":4294967295}],"vout":[{"value":50.00000000,"n":0,"scriptPubKey":{"asm":"OP_DUP OP_HASH160 b44afd6e2b4dd224e3eb7050c46dd11f9be78a96 OP_EQUALVERIFY OP_CHECKSIG","desc":"addr(mwxFkyeJJDvq2VmrbJA2eVN4ywSdyVXEdk)#mjqgx25y","hex":"76a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac","address":"mwxFkyeJJDvq2VmrbJA2eVN4ywSdyVXEdk","type":"pubkeyhash"}},{"value":0.00000000,"n":1,"scriptPubKey":{"asm":"OP_RETURN aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9","desc":"raw(6a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9)#cav96mf3","hex":"6a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9","type":"nulldata"}}],"hex":"020000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff025200ffffffff0200f2052a010000001976a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac0000000000000000266a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf90120000000000000000000000000000000000000000000000000000000000000000000000000","blockhash":"6c21927406ddec799f11ba70a798c8169ca3ad7a540cc720cc4cf364018b4aec","confirmations":1,"time":1674683108,"blocktime":1674683108}
"""
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        guard
            let jsonData = json.data(using: .utf8),
            let decoded = try? d.decode(CoreTx.self, from: jsonData)
        else {
            XCTFail()
            return
        }
        
        let constructed = CoreTx(
            txid: "9c218eb2aef4450b1dec636b1c4c11f6b42e1b56074f36fc5998537457037ec1",
            hash: "d8cb1301bda5ccaf80be773835c120ae04b25a35bd319d4c2e7f2cba6c70e6dd",
            version: 2,
            size: 170,
            vsize: 143,
            weight: 572,
            locktime: 0,
            vin: [
                .init(
                    coinbase: "5200",
                    scriptSig: .none,
                    txid: .none,
                    vout: .none,
                    txinwitness: ["0000000000000000000000000000000000000000000000000000000000000000"],
                    sequence: 4294967295)
            ],
            vout: [
                .init(
                    value: 50,
                    n: 0,
                    scriptPubKey: .init(
                        asm: "OP_DUP OP_HASH160 b44afd6e2b4dd224e3eb7050c46dd11f9be78a96 OP_EQUALVERIFY OP_CHECKSIG",
                        desc: "addr(mwxFkyeJJDvq2VmrbJA2eVN4ywSdyVXEdk)#mjqgx25y",
                        hex: "76a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac",
                        address: "mwxFkyeJJDvq2VmrbJA2eVN4ywSdyVXEdk",
                        type: .pubKeyHash
                    )
                ),
                .init(
                    value: 0,
                    n: 1,
                    scriptPubKey: .init(
                        asm: "OP_RETURN aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9",
                        desc: "raw(6a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9)#cav96mf3",
                        hex: "6a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9",
                        address: .none,
                        type: .nullData
                    )
                )
            ],
            hex: "020000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff025200ffffffff0200f2052a010000001976a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac0000000000000000266a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf90120000000000000000000000000000000000000000000000000000000000000000000000000",
            blockhash: "6c21927406ddec799f11ba70a798c8169ca3ad7a540cc720cc4cf364018b4aec",
            confirmations: 1,
            time: Date(timeIntervalSince1970: 1674683108),
            blocktime: 1674683108
        )
        XCTAssertEqual(decoded, constructed)
    }
}
