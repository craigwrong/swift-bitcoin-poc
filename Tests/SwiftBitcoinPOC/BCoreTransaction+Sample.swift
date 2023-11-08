@testable import SwiftBitcoinPOC
import Foundation

extension CoreTx {
    
    struct Sample {
        
        /// Ephimeral regtest coinbase transaction
        static let coinbase1 = CoreTx(
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
                    sequence: 4294967295
                )
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
                        type: .publicKeyHash
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
        
        static let coinbase1NoAddressDescriptor = CoreTx(
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
                    sequence: 4294967295
                )
            ],
            vout: [
                .init(
                    value: 50,
                    n: 0,
                    scriptPubKey: .init(
                        asm: "OP_DUP OP_HASH160 b44afd6e2b4dd224e3eb7050c46dd11f9be78a96 OP_EQUALVERIFY OP_CHECKSIG",
                        desc: "",
                        hex: "76a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac",
                        address: "",
                        type: .publicKeyHash
                    )
                ),
                .init(
                    value: 0,
                    n: 1,
                    scriptPubKey: .init(
                        asm: "OP_RETURN aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9",
                        desc: "",
                        hex: "6a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf9",
                        address: "", //.none,
                        type: .nullData
                    )
                )
            ],
            hex: "020000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff025200ffffffff0200f2052a010000001976a914b44afd6e2b4dd224e3eb7050c46dd11f9be78a9688ac0000000000000000266a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf90120000000000000000000000000000000000000000000000000000000000000000000000000",
            blockhash: .none,
            confirmations: .none,
            time: .none,
            blocktime: .none
        )
        
        static let segwit1 = try! JSONDecoder().decode(CoreTx.self, from: """
    {
      "txid": "33684826ae8b25e6e15eb9007b71a5248ebff9da5bfed84c739f89ccc9c4cf7e",
      "hash": "83caf3bd74e0d5a54c6659727b1813bd1d123c9f9351ca4dd22e9fc80609b85d",
      "version": 2,
      "size": 222,
      "vsize": 141,
      "weight": 561,
      "locktime": 109,
      "vin": [
        {
          "txid": "d4a10489fc1722db787e0bd2a55aa0a2c0a6b1371caef04079fa2338b44d0f99",
          "vout": 1,
          "scriptSig": {
            "asm": "",
            "hex": ""
          },
          "txinwitness": [
            "30440220456e792256fa917f5dc572dadf82e1d711b3fd18cdcf946ffc83ac4872c120d802203fb2dc748ea623591406039a8a11e60302a18235b2999bd161d5d690703e269e01",
            "03d105d65175372e0bab204af950356422f45af3605bc499d8cd13914346be9e69"
          ],
          "sequence": 4294967293
        }
      ],
      "vout": [
        {
          "value": 0.10000000,
          "n": 0,
          "scriptPubKey": {
            "asm": "0 b42c2a34d039ebbe5eb7525830a3e30c059fd634",
            "desc": "addr(bcrt1qkskz5dxs884muh4h2fvrpglrpszel43552r32s)#re7ft07r",
            "hex": "0014b42c2a34d039ebbe5eb7525830a3e30c059fd634",
            "address": "bcrt1qkskz5dxs884muh4h2fvrpglrpszel43552r32s",
            "type": "witness_v0_keyhash"
          }
        },
        {
          "value": 0.89999859,
          "n": 1,
          "scriptPubKey": {
            "asm": "0 d8d5b8d4dc7635db74ba6630188c4c839f19beb8",
            "desc": "addr(bcrt1qmr2m34xuwc6aka96vccp3rzvsw03n04ckhqjz8)#hvece4xr",
            "hex": "0014d8d5b8d4dc7635db74ba6630188c4c839f19beb8",
            "address": "bcrt1qmr2m34xuwc6aka96vccp3rzvsw03n04ckhqjz8",
            "type": "witness_v0_keyhash"
          }
        }
      ],
      "hex": "02000000000101990f4db43823fa7940f0ae1c37b1a6c0a2a05aa5d20b7e78db2217fc8904a1d40100000000fdffffff028096980000000000160014b42c2a34d039ebbe5eb7525830a3e30c059fd634f3495d0500000000160014d8d5b8d4dc7635db74ba6630188c4c839f19beb8024730440220456e792256fa917f5dc572dadf82e1d711b3fd18cdcf946ffc83ac4872c120d802203fb2dc748ea623591406039a8a11e60302a18235b2999bd161d5d690703e269e012103d105d65175372e0bab204af950356422f45af3605bc499d8cd13914346be9e696d000000",
      "blockhash": "5e64046c5887232b19157f583af876314807cc048efc1a9ce12058a31ce55f95",
      "confirmations": 1,
      "time": 1675282384,
      "blocktime": 1675282384
    }
    """.data(using: .utf8)!)
        
        static let segwit1NoDescriptor = try! JSONDecoder().decode(CoreTx.self, from: """
    {
      "txid": "33684826ae8b25e6e15eb9007b71a5248ebff9da5bfed84c739f89ccc9c4cf7e",
      "hash": "83caf3bd74e0d5a54c6659727b1813bd1d123c9f9351ca4dd22e9fc80609b85d",
      "version": 2,
      "size": 222,
      "vsize": 141,
      "weight": 561,
      "locktime": 109,
      "vin": [
        {
          "txid": "d4a10489fc1722db787e0bd2a55aa0a2c0a6b1371caef04079fa2338b44d0f99",
          "vout": 1,
          "scriptSig": {
            "asm": "",
            "hex": ""
          },
          "txinwitness": [
            "30440220456e792256fa917f5dc572dadf82e1d711b3fd18cdcf946ffc83ac4872c120d802203fb2dc748ea623591406039a8a11e60302a18235b2999bd161d5d690703e269e01",
            "03d105d65175372e0bab204af950356422f45af3605bc499d8cd13914346be9e69"
          ],
          "sequence": 4294967293
        }
      ],
      "vout": [
        {
          "value": 0.10000000,
          "n": 0,
          "scriptPubKey": {
            "asm": "0 b42c2a34d039ebbe5eb7525830a3e30c059fd634",
            "desc": "",
            "hex": "0014b42c2a34d039ebbe5eb7525830a3e30c059fd634",
            "address": "bcrt1qkskz5dxs884muh4h2fvrpglrpszel43552r32s",
            "type": "witness_v0_keyhash"
          }
        },
        {
          "value": 0.89999859,
          "n": 1,
          "scriptPubKey": {
            "asm": "0 d8d5b8d4dc7635db74ba6630188c4c839f19beb8",
            "desc": "",
            "hex": "0014d8d5b8d4dc7635db74ba6630188c4c839f19beb8",
            "address": "bcrt1qmr2m34xuwc6aka96vccp3rzvsw03n04ckhqjz8",
            "type": "witness_v0_keyhash"
          }
        }
      ],
      "hex": "02000000000101990f4db43823fa7940f0ae1c37b1a6c0a2a05aa5d20b7e78db2217fc8904a1d40100000000fdffffff028096980000000000160014b42c2a34d039ebbe5eb7525830a3e30c059fd634f3495d0500000000160014d8d5b8d4dc7635db74ba6630188c4c839f19beb8024730440220456e792256fa917f5dc572dadf82e1d711b3fd18cdcf946ffc83ac4872c120d802203fb2dc748ea623591406039a8a11e60302a18235b2999bd161d5d690703e269e012103d105d65175372e0bab204af950356422f45af3605bc499d8cd13914346be9e696d000000"
    }
    """.data(using: .utf8)!)
        
        static let segwitPrevious1 = try! JSONDecoder().decode(CoreTx.self, from: """
    {
      "txid": "d4a10489fc1722db787e0bd2a55aa0a2c0a6b1371caef04079fa2338b44d0f99",
      "hash": "d4a10489fc1722db787e0bd2a55aa0a2c0a6b1371caef04079fa2338b44d0f99",
      "version": 2,
      "size": 219,
      "vsize": 219,
      "weight": 876,
      "locktime": 108,
      "vin": [
        {
          "txid": "4b4c03b9dbd208fbd1e89df28fedff9608ddc3cb047ded487cd3adf333ceb37d",
          "vout": 0,
          "scriptSig": {
            "asm": "304402201518c1797df55a21ad624a515192079fb3a47d3269eb909a14f216b7ca79cba10220412ca685e7afa478191e07e35189f1057631355345f4c4eae05abb3a97e8aa77[ALL] 03074a6ef1f0c73a2631b8162c1723fad493c3c125603e8b8bc95a24d8f54e76a7",
            "hex": "47304402201518c1797df55a21ad624a515192079fb3a47d3269eb909a14f216b7ca79cba10220412ca685e7afa478191e07e35189f1057631355345f4c4eae05abb3a97e8aa77012103074a6ef1f0c73a2631b8162c1723fad493c3c125603e8b8bc95a24d8f54e76a7"
          },
          "sequence": 4294967293
        }
      ],
      "vout": [
        {
          "value": 48.99999781,
          "n": 0,
          "scriptPubKey": {
            "asm": "0 ea9a6440fa6c6ec96019d4b2a8d28ee50b307d86",
            "desc": "addr(bcrt1qa2dxgs86d3hvjcqe6je2355wu59nqlvx9lc2gw)#0zscaagw",
            "hex": "0014ea9a6440fa6c6ec96019d4b2a8d28ee50b307d86",
            "address": "bcrt1qa2dxgs86d3hvjcqe6je2355wu59nqlvx9lc2gw",
            "type": "witness_v0_keyhash"
          }
        },
        {
          "value": 1.00000000,
          "n": 1,
          "scriptPubKey": {
            "asm": "0 dbb6d1b7ec86fa0dd549122de836cb2a1b443e91",
            "desc": "addr(bcrt1qmwmdrdlvsmaqm42fzgk7sdkt9gd5g05336p434)#ucslf8fz",
            "hex": "0014dbb6d1b7ec86fa0dd549122de836cb2a1b443e91",
            "address": "bcrt1qmwmdrdlvsmaqm42fzgk7sdkt9gd5g05336p434",
            "type": "witness_v0_keyhash"
          }
        }
      ],
      "hex": "02000000017db3ce33f3add37c48ed7d04cbc3dd0896ffed8ff29de8d1fb08d2dbb9034c4b000000006a47304402201518c1797df55a21ad624a515192079fb3a47d3269eb909a14f216b7ca79cba10220412ca685e7afa478191e07e35189f1057631355345f4c4eae05abb3a97e8aa77012103074a6ef1f0c73a2631b8162c1723fad493c3c125603e8b8bc95a24d8f54e76a7fdffffff022510102401000000160014ea9a6440fa6c6ec96019d4b2a8d28ee50b307d8600e1f50500000000160014dbb6d1b7ec86fa0dd549122de836cb2a1b443e916c000000",
      "blockhash": "6d244de0191ec89545b8fa95000fb9cd2171736e8762f2b6aa8f6cfc1605f1ac",
      "confirmations": 2,
      "time": 1675282288,
      "blocktime": 1675282288
    }
    """.data(using: .utf8)!)
        
        static let segwit1Spend = try! JSONDecoder().decode(CoreTx.self, from: """
            {
              "txid": "bfd84e3d4be7ca792179d8360e915d800c09d22fd378025eaa13f2a1607066fc",
              "hash": "acb417f33c8412eece0bf8dde0444379adae6f888a3c65fd1070474dd8da7996",
              "version": 2,
              "size": 191,
              "vsize": 110,
              "weight": 437,
              "locktime": 0,
              "vin": [
                {
                  "txid": "33684826ae8b25e6e15eb9007b71a5248ebff9da5bfed84c739f89ccc9c4cf7e",
                  "vout": 0,
                  "scriptSig": {
                    "asm": "",
                    "hex": ""
                  },
                  "txinwitness": [
                    "3044022061b843dd812f30aa0936cd00fb6a2b3205ef5515e76b6a71a56c9a85a55b0dc902205d1c75097e60a5ede0f7d0347bdc5dcf5b74442eda7595a96fcf47b8e761fe9301",
                    "02f92957572bd9fbe6583b2e60cd0b8b9e82307f5865520a5d69a65f6929eb55ef"
                  ],
                  "sequence": 4294967293
                }
              ],
              "vout": [
                {
                  "value": 0.09999890,
                  "n": 0,
                  "scriptPubKey": {
                    "asm": "0 84331aa63cbd5aeea6b4d4d989305183e7cc55ec",
                    "desc": "addr(bcrt1qsse34f3uh4dwaf456nvcjvz3s0nuc40veml8k4)#zvae8k5l",
                    "hex": "001484331aa63cbd5aeea6b4d4d989305183e7cc55ec",
                    "address": "bcrt1qsse34f3uh4dwaf456nvcjvz3s0nuc40veml8k4",
                    "type": "witness_v0_keyhash"
                  }
                }
              ],
              "hex": "020000000001017ecfc4c9cc899f734cd8fe5bdaf9bf8e24a5717b00b95ee1e6258bae264868330000000000fdffffff01129698000000000016001484331aa63cbd5aeea6b4d4d989305183e7cc55ec02473044022061b843dd812f30aa0936cd00fb6a2b3205ef5515e76b6a71a56c9a85a55b0dc902205d1c75097e60a5ede0f7d0347bdc5dcf5b74442eda7595a96fcf47b8e761fe93012102f92957572bd9fbe6583b2e60cd0b8b9e82307f5865520a5d69a65f6929eb55ef00000000"
            }
        """.data(using: .utf8)!)
    }
}
