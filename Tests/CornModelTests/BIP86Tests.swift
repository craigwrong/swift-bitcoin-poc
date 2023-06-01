import XCTest
@testable import CornModel

/// https://github.com/bitcoin/bips/blob/master/bip-0086.mediawiki#Test_vectors
final class BIP86Tests: XCTestCase {
    
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }

    func testP2TROutputs() {
        /*
         mnemonic = abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
         rootpriv = xprv9s21ZrQH143K3GJpoapnV8SFfukcVBSfeCficPSGfubmSFDxo1kuHnLisriDvSnRRuL2Qrg5ggqHKNVpxR86QEC8w35uxmGoggxtQTPvfUu
         rootpub  = xpub661MyMwAqRbcFkPHucMnrGNzDwb6teAX1RbKQmqtEF8kK3Z7LZ59qafCjB9eCRLiTVG3uxBxgKvRgbubRhqSKXnGGb1aoaqLrpMBDrVxga8

         // Account 0, root = m/86'/0'/0'
         xprv = xprv9xgqHN7yz9MwCkxsBPN5qetuNdQSUttZNKw1dcYTV4mkaAFiBVGQziHs3NRSWMkCzvgjEe3n9xV8oYywvM8at9yRqyaZVz6TYYhX98VjsUk
         xpub = xpub6BgBgsespWvERF3LHQu6CnqdvfEvtMcQjYrcRzx53QJjSxarj2afYWcLteoGVky7D3UKDP9QyrLprQ3VCECoY49yfdDEHGCtMMj92pReUsQ

         // Account 0, first receiving address = m/86'/0'/0'/0/0
         xprv         = xprvA449goEeU9okwCzzZaxiy475EQGQzBkc65su82nXEvcwzfSskb2hAt2WymrjyRL6kpbVTGL3cKtp9herYXSjjQ1j4stsXXiRF7kXkCacK3T
         xpub         = xpub6H3W6JmYJXN49h5TfcVjLC3onS6uPeUTTJoVvRC8oG9vsTn2J8LwigLzq5tHbrwAzH9DGo6ThGUdWsqce8dGfwHVBxSbixjDADGGdzF7t2B
         
         // Calculated with `bx hd-to-ec`
         sec_key = 41f41d69260df4cf277826a9b65a3717e4eeddbeedf637f212ca096576479361
         pub_key = 03cc8a4bc64d897bddc5fbc2f670f7a8ba0b386779106cf1223c6fc5d7cd6fc115
         
         internal_key = cc8a4bc64d897bddc5fbc2f670f7a8ba0b386779106cf1223c6fc5d7cd6fc115
         output_key   = a60869f0dbcf1dc659c9cecbaf8050135ea9e8cdc487053f1dc6880949dc684c
         scriptPubKey = 5120a60869f0dbcf1dc659c9cecbaf8050135ea9e8cdc487053f1dc6880949dc684c
         address      = bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr

         // Account 0, second receiving address = m/86'/0'/0'/0/1
         xprv         = xprvA449goEeU9okyiF1LmKiDaTgeXvmh87DVyRd35VPbsSop8n8uALpbtrUhUXByPFKK7C2yuqrB1FrhiDkEMC4RGmA5KTwsE1aB5jRu9zHsuQ
         xpub         = xpub6H3W6JmYJXN4CCKUSnriaiQRCZmG6aq4sCMDqTu1ACyngw7HShf59hAxYjXgKDuuHThVEUzdHrc3aXCr9kfvQvZPit5dnD3K9xVRBzjK3rX

         // Calculated with `bx hd-to-ec`
         sec_key = 86c68ac0ed7df88cbdd08a847c6d639f87d1234d40503abf3ac178ef7ddc05dd
         pub_key = 0283dfe85a3151d2517290da461fe2815591ef69f2b18a2ce63f01697a8b313145

         internal_key = 83dfe85a3151d2517290da461fe2815591ef69f2b18a2ce63f01697a8b313145
         output_key   = a82f29944d65b86ae6b5e5cc75e294ead6c59391a1edc5e016e3498c67fc7bbb
         scriptPubKey = 5120a82f29944d65b86ae6b5e5cc75e294ead6c59391a1edc5e016e3498c67fc7bbb
         address      = bc1p4qhjn9zdvkux4e44uhx8tc55attvtyu358kutcqkudyccelu0was9fqzwh

         // Account 0, first change address = m/86'/0'/0'/1/0
         xprv         = xprvA3Ln3Gt3aphvUgzgEDT8vE2cYqb4PjFfpmbiFKphxLg1FjXQpkAk5M1ZKDY15bmCAHA35jTiawbFuwGtbDZogKF1WfjwxML4gK7WfYW5JRP
         xpub         = xpub6GL8SnQwRCGDhB59LEz9HMyM6sRYoByXBzXK3iEKWgCz8XrZNHUzd9L3AUBELW5NzA7dEFvMas1F84TuPH3xqdUA5tumaGWFgihJzWytXe3

         // Calculated with `bx hd-to-ec`
         sec_key = 6ccbca4a02ac648702dde463d9c1b0d328a4df1e068ef9dc2bc788b33a4f0412
         pub_key = 02399f1b2f4393f29a18c937859c5dd8a77350103157eb880f02e8c08214277cef

         internal_key = 399f1b2f4393f29a18c937859c5dd8a77350103157eb880f02e8c08214277cef
         output_key   = 882d74e5d0572d5a816cef0041a96b6c1de832f6f9676d9605c44d5e9a97d3dc
         scriptPubKey = 5120882d74e5d0572d5a816cef0041a96b6c1de832f6f9676d9605c44d5e9a97d3dc
         address      = bc1p3qkhfews2uk44qtvauqyr2ttdsw7svhkl9nkm9s9c3x4ax5h60wqwruhk7
         */
    }
}
