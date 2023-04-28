import XCTest
import CornModel

final class RegtestTests: XCTestCase {
    override class func setUp() {
        eccStart()
    }

    override class func tearDown() {
        eccStop()
    }

    func testLegacy_pyBitcoin_all() {
        var unsignedTx = Tx(Data(hex: "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb0000000000ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a914c992931350c9ba48538003706953831402ea34ea88ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
            .dup,
            .hash160,
            .pushBytes(Data(hex: "c3f8e5b0f8455a2b02c29c4488a550278209b669")),
            .equalVerify,
            .checkSig
        ]).data)]
        let privKey0 = Data(hex: "81c70e36ffa5e3e6425dc19c7c35315d3d72dc60b79cb78fe009a335de29dd2201") // cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9
        let pubKey0 = Data(hex: "03a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708")
        
        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .all, inIdx: 0, prevOuts: prevOuts)
        
        XCTAssertEqual(signedTx.data.hex, "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a473044022079dad1afef077fa36dcd3488708dd05ef37888ef550b45eb00cdb04ba3fc980e02207a19f6261e69b604a92e2bffdf6ddbed0c64f55d5003e9dfb58b874b07aef3d7012103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a914c992931350c9ba48538003706953831402ea34ea88ac00000000")
    }
    
    func testLegacy_pyBitcoin2_all() {
        var unsignedTx = Tx(Data(hex: "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb0000000000ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
            .dup,
            .hash160,
            .pushBytes(Data(hex: "c3f8e5b0f8455a2b02c29c4488a550278209b669")),
            .equalVerify,
            .checkSig
        ]).data)]
        let privKey0 = Data(hex: "81c70e36ffa5e3e6425dc19c7c35315d3d72dc60b79cb78fe009a335de29dd2201") // cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9
        let pubKey0 = Data(hex: "03a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708")
        
        let sigMsg = unsignedTx.sigMsg(hashType: .all, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988acffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac0000000001000000")
        
        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .all, inIdx: 0, prevOuts: prevOuts)
        
        XCTAssertEqual(signedTx.data.hex, "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a473044022044ef433a24c6010a90af14f7739e7c60ce2c5bc3eab96eaee9fbccfdbb3e272202205372a617cb235d0a0ec2889dbfcadf15e10890500d184c8dda90794ecdf79492012103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")
    }

    func testLegacy_pyBitcoin2_none() {
        var unsignedTx = Tx(Data(hex: "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb0000000000ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
            .dup,
            .hash160,
            .pushBytes(Data(hex: "c3f8e5b0f8455a2b02c29c4488a550278209b669")),
            .equalVerify,
            .checkSig
        ]).data)]
        let privKey0 = Data(hex: "81c70e36ffa5e3e6425dc19c7c35315d3d72dc60b79cb78fe009a335de29dd2201") // cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9
        let pubKey0 = Data(hex: "03a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708")
        let sigMsg = unsignedTx.sigMsg(hashType: .none, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988acffffffff000000000002000000")

        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .none, inIdx: 0, prevOuts: prevOuts)
        
        // XCTAssertEqual(signedTx.data.hex, "02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a47304402201e4b7a2ed516485fdde697ba63f6670d43aa6f18d82f18bae12d5fd228363ac10220670602bec9df95d7ec4a619a2f44e0b8dcf522fdbe39530dd78d738c0ed0c430022103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")
    }
    
    func testLegacy_pyBitcoin2x2_all() {
        var unsignedTx = Tx(Data(hex: "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760000000000ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760100000000ffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000"))
        
        let prevOuts = [
            Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(Data(hex: "fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a")),
                .equalVerify,
                .checkSig
            ]).data),
            Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(Data(hex: "42151d0c21442c2b038af0ad5ee64b9d6f4f4e49")),
                .equalVerify,
                .checkSig
            ]).data)
        ]
        let privKey0 = Data(hex: "a67d3c308333c63f5e83a75e42a5533d0ac27153ecf443dd75cd4306d0c68fba01") // cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo
        let pubKey0 = Data(hex: "02d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546")
        
        let sigMsg0 = unsignedTx.sigMsg(hashType: .all, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg0.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88acffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760100000000ffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac0000000001000000")

        var signedTx0 = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .all, inIdx: 0, prevOuts: prevOuts)
        
        let privKey1 = Data(hex: "f0ef687ea00a50936b659748b89a5b65dff8b3cea215d33f5d8c0917faab9c4301") // cVf3kGh6552jU2rLaKwXTKq5APHPoZqCP4GQzQirWGHFoHQ9rEVt
        let pubKey1 = Data(hex: "02364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5d")
        
        let sigMsg1 = unsignedTx.sigMsg(hashType: .all, inIdx: 1, subScript: prevOuts[1].scriptPubKey)
        XCTAssertEqual(sigMsg1.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760000000000ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988acffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac0000000001000000")
        
        let signedTx = signedTx0.signInput(privKey: privKey1, pubKey: pubKey1, hashType: .all, inIdx: 1, prevOuts: prevOuts)

        // BITCOIN CORE: XCTAssertEqual(signedTx.data.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a4730440220355c3cf50b1d320d4ddfbe1b407ddbe508f8e31a38cc5531dec3534e8cb2e565022037d4e8d7ba9dd1c788c0d8b5b99270d4c1d4087cdee7f139a71fea23dceeca33012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a47304402206b728374b8879fd7a10cbd4f347934d583f4301aa5d592211487732c235b85b6022030acdc07761f227c27010bd022df4b22eb9875c65a59e8e8a5722229bc7362f4012102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")
        
        // Py Bitcoin Utils gives another signature
        XCTAssertEqual(signedTx.data.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402204e31dc9f73c3ee1d505ba9938920c32bfb9f47eddec1b79545720f73e34a1291022068eff276b3fddd1c28966cd7d017261bb3773a7fd74acd8cf56b939478f1767e012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a473044022028ac68cc7781c9fbae413dad150b5445e5240a85fff843e739b5fb56b481875302202d7daa70aaf512302c8a1fe05c37e45e8e9f72a7c98bcb3462c7cf1cbb22e13e012102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")

    }
    
    func testLegacy_pyBitcoin2x2_none() {
        var unsignedTx = Tx(Data(hex: "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760000000000ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760100000000ffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000"))
        
        let prevOuts = [
            Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(Data(hex: "fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a")),
                .equalVerify,
                .checkSig
            ]).data),
            Tx.Out(value: UInt64(0), scriptPubKeyData: ScriptLegacy([
                .dup,
                .hash160,
                .pushBytes(Data(hex: "42151d0c21442c2b038af0ad5ee64b9d6f4f4e49")),
                .equalVerify,
                .checkSig
            ]).data)
        ]
        
        let privKey0 = Data(hex: "a67d3c308333c63f5e83a75e42a5533d0ac27153ecf443dd75cd4306d0c68fba01") // cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo
        let pubKey0 = Data(hex: "02d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546")
        
        let sigMsg0 = unsignedTx.sigMsg(hashType: .none, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg0.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88acffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000000000000000000000000002000000")

        var signedTx0 = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .none, inIdx: 0, prevOuts: prevOuts)
        
        let privKey1 = Data(hex: "f0ef687ea00a50936b659748b89a5b65dff8b3cea215d33f5d8c0917faab9c4301") // cVf3kGh6552jU2rLaKwXTKq5APHPoZqCP4GQzQirWGHFoHQ9rEVt
        let pubKey1 = Data(hex: "02364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5d")
        
        let sigMsg1 = unsignedTx.sigMsg(hashType: .none, inIdx: 1, subScript: prevOuts[1].scriptPubKey)
        XCTAssertEqual(sigMsg1.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c46760000000000000000000f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988acffffffff000000000002000000")

        let signedTx = signedTx0.signInput(privKey: privKey1, pubKey: pubKey1, hashType: .none, inIdx: 1, prevOuts: prevOuts)

        // Bitcoin Core Result: XCTAssertEqual(signedTx.data.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402202a2804048b7f84f2dd7641ec05bbaf3da9ae0d2a9f9ad476d376adfd8bf5033302205170fee2ab7b955d72ae2beac3bae15679d75584c37d78d82b07df5402605bab022102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a473044022021a82914b002bd02090fbdb37e2e739e9ba97367e74db5e1de834bbab9431a2f02203a11f49a3f6ac03b1550ee04f9d84deee2045bc038cb8c3e70869470126a064d022102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")

        XCTAssertEqual(signedTx.data.hex, "02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402202a2804048b7f84f2dd7641ec05bbaf3da9ae0d2a9f9ad476d376adfd8bf5033302205170fee2ab7b955d72ae2beac3bae15679d75584c37d78d82b07df5402605bab022102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a473044022021a82914b002bd02090fbdb37e2e739e9ba97367e74db5e1de834bbab9431a2f02203a11f49a3f6ac03b1550ee04f9d84deee2045bc038cb8c3e70869470126a064d022102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988ac40548900000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000")
    }

    func testLegacy_1to1_all() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOut0 = Tx.Out(value: UInt64(0), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125") // 03ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e mrVceFBXfu9MJwdbiWFB2A6cpiWb4j1n27
        
        let sigMsg = unsignedTx.sigMsg(hashType: .all, inIdx: 0, subScript: prevOut0.scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000001976a914786890276a55f3e6d2f403e3d595b6603964fa0d88acfdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac0000000001000000")
        let sigHash = unsignedTx.sigHash(.all, inIdx: 0, prevOut: prevOut0, scriptCode: prevOut0.scriptPubKey, opIdx: 0)
        let sig = signECDSA(msg: sigHash, privKey: privKey0)
        XCTAssertTrue(unsignedTx.checkSig(sig + HashType.all.data, pubKey: pubKey0, inIdx: 0, prevOut: prevOut0, scriptCode: prevOut0.scriptPubKey, opIdx: 0))
        

        // Since Core generates a different signature, let's at least make sure that their signature also verifies our hash.
        let coreHex = "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022037b8b0c1a33caa83be5eb71f87bce5dbd4890a56a61b98d9d603e754313fadc602201ef00773d2e0b98d558f0a1ac89a1fad1da15f852140fca5f5d737c0025e11ad014104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"
        let coreTx = Tx(Data(hex: coreHex))
        let coreOp = coreTx.ins[0].scriptSig.ops[0]
        if case .pushBytes(let hashType) = coreOp {
            XCTAssertTrue(unsignedTx.checkSig(hashType, pubKey: pubKey0, inIdx: 0, prevOut: prevOut0, scriptCode: prevOut0.scriptPubKey, opIdx: 0))
        } else {
            XCTFail("Could not extract signature from transaction.")
        }

        // let signedTx = unsignedTx.signed(privKey: privKey0, pubKey: pubKey0, inIdx: 0, prevOut: prevOut0, hashType: .all)
        //XCTAssertEqual(signedTx.data.hex, coreHex)
    }
    
    func testLegacy_1to1_allAny() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOuts = [
            Tx.Out(value: UInt64(0), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))
        ]
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        
        let sigMsg = unsignedTx.sigMsg(hashType: .allAnyCanPay, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000001976a914786890276a55f3e6d2f403e3d595b6603964fa0d88acfdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac0000000081000000")


        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .allAnyCanPay, inIdx: 0, prevOuts: prevOuts)
        
        //XCTAssertEqual(signedTx.data.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022071d3102292c188fb2be5878ac2a34241f49538352435642087ff2350fd5a05040220755797e78c480a4c8fdd47e1dd37ff6e8e343a188d2056ceb894a681d72d7b7c814104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000")
    }

    func testLegacy_1to1_none() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOuts = [
            Tx.Out(value: UInt64(0), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))
        ]
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        
        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .none, inIdx: 0, prevOuts: prevOuts)
        
        XCTAssertEqual(signedTx.data.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022007702cdcd60c839aa437104cc7c60ae5349bf1398534ff35000bb70ac7aafe1802202350ec73fdb2f61b8f4d9c84a75abed5b85d67b041befe0bd3b8c43e9d51a59a024104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000")
    }
    
    func testLegacy_1to1_noneAny() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(0), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))]
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        
        let sigMsg = unsignedTx.sigMsg(hashType: .noneAnyCanPay, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000001976a914786890276a55f3e6d2f403e3d595b6603964fa0d88acfdffffff000000000082000000")

        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .noneAnyCanPay, inIdx: 0, prevOuts: prevOuts)
        
        // XCTAssertEqual(signedTx.data.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a4730440220452a9f5a9352adf18b9c0655e522fa12b4129ede95313f0466f5e295bed6d5fa02201fd4122dba88b10e0b9340ff51dafb3c16333cc7e7ce4c7c71d6455487b53360824104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000")
    }
    
    func testLegacy_1to1_single() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(0), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))]
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        
        let sigMsg = unsignedTx.sigMsg(hashType: .single, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000001976a914786890276a55f3e6d2f403e3d595b6603964fa0d88acfdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac0000000003000000")

        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .single, inIdx: 0, prevOuts: prevOuts)
        
        // XCTAssertEqual(signedTx.data.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022001ae1405bb1d058d34eed774ff8f8dcd0ba02f422f37308b9860c5d19838757902203e28313c6f0f558e1965770ae7ff377377de67e293ed21db113b7bf49738e816034104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000")
    }

    func testLegacy_1to1_singleAny() {
        var unsignedTx = Tx(Data(hex: "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da20000000000fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000"))
        
        let prevOuts = [Tx.Out(value: UInt64(312500000), scriptPubKeyData: .init(hex: "76a914786890276a55f3e6d2f403e3d595b6603964fa0d88ac"))]
        let privKey0 = Data(hex: "828748ccadd3792f39841749da9618389dcce35ace39d94b131ae8d8a359804c") // 92aQLXE8yvQ1qHoXvPCSSoLP3AM65g98Pavxsb53MTdTv1BgKXE
        let pubKey0 = Data(hex: "04ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125")
        
        let sigMsg = unsignedTx.sigMsg(hashType: .singleAnyCanPay, inIdx: 0, subScript: prevOuts[0].scriptPubKey)
        XCTAssertEqual(sigMsg.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000001976a914786890276a55f3e6d2f403e3d595b6603964fa0d88acfdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac0000000083000000")

        let signedTx = unsignedTx.signInput(privKey: privKey0, pubKey: pubKey0, hashType: .singleAnyCanPay, inIdx: 0, prevOuts: prevOuts)
        
        //XCTAssertEqual(signedTx.data.hex, "0200000001579639e3c861067e4eccedbc3fcf801a825509b393657a0994b0b2ca6b4a5da2000000008a473044022032bfe478986429ea3b74df0115385c87567ec0637bef8565f7245d3177212c4d022015826bd4764633d00a17f61a439c462ff5ec978acfbd6e94c6146153ac252d80834104ce88102d2af294198df851e4776e4c505e2f288cb253a244f69fb0ddc656f11e1286fb9309a39a92553e2ce3969eeb92ed30bd402a7cbc62ec7d7a4e32f7c125fdffffff0100e1f505000000001976a9145a1c620bc593fa5ae99df3520c4282fcbded1c6788ac00000000")
    }
}
