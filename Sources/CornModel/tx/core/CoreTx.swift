import Foundation

struct CoreTx: Equatable, Decodable {
    
    init(txid: String, hash: String, version: UInt32, size: Int, vsize: Int, weight: Int, locktime: UInt32, vin: [CoreTx.Input], vout: [CoreTx.Output], hex: String, blockhash: String?, confirmations: Int?, time: Date?, blocktime: Int?) {
        self.txid = txid
        self.hash = hash
        self.version = version
        self.size = size
        self.vsize = vsize
        self.weight = weight
        self.locktime = locktime
        self.vin = vin
        self.vout = vout
        self.hex = hex
        self.blockhash = blockhash
        self.confirmations = confirmations
        self.time = time
        self.blocktime = blocktime
    }

    let txid: String
    let hash: String
    let version: UInt32
    let size: Int
    let vsize: Int
    let weight: Int
    let locktime: UInt32
    let vin: [Input]
    let vout: [Output]
    let hex: String
    let blockhash: String?
    let confirmations: Int?
    let time: Date?
    let blocktime: Int?
}

extension CoreTx {
    
    var toBitcoinTransaction: Tx {
        .init(Data(hex: hex))
    }
    
    struct Input: Equatable, Decodable {
        
         init(coinbase: String? = nil, scriptSig: CoreTx.Input.UnlockScript? = nil, txid: String? = nil, vout: Int? = nil, txinwitness: [String]? = nil, sequence: UInt32) {
            self.coinbase = coinbase
            self.scriptSig = scriptSig
            self.txid = txid
            self.vout = vout
            self.txinwitness = txinwitness
            self.sequence = sequence
        }
        
        
        struct UnlockScript: Equatable, Decodable {
            init(asm: String, hex: String) {
                self.asm = asm
                self.hex = hex
            }
            
            let asm: String
            let hex: String
        }

        // Either coinbase (scriptsig)
        let coinbase: String?
        
        // Either scriptsig
        let scriptSig: UnlockScript?
        let txid: String?
        let vout: Int?
        
        let txinwitness: [String]?
        
        let sequence: UInt32
    }
    
    struct Output: Equatable, Decodable {
        
        init(value: Double, n: Int, scriptPubKey: CoreTx.Output.LockScript) {
            self.value = value
            self.n = n
            self.scriptPubKey = scriptPubKey
        }
        
        struct LockScript: Equatable, Decodable {
            
            init(asm: String, desc: String, hex: String, address: String? = nil, type: CoreTx.Output.LockScript.ScriptType) {
                self.asm = asm
                self.desc = desc
                self.hex = hex
                self.address = address
                self.type = type
            }
            
            enum ScriptType: String, Equatable, Decodable {
                case witness_v0_keyhash, pubkeyhash, nulldata, unknown
            }
            
            let asm: String
            let desc: String
            let hex: String
            let address: String?
            let type: ScriptType
        }
        
        let value: Double
        let n: Int
        let scriptPubKey: LockScript
    }
}

extension Tx {
    func toBCoreTransaction(network: Network = .main) -> CoreTx {
        .init(
            txid: txid,
            hash: wtxid,
            version: version.uInt32,
            size: size,
            vsize: vsize,
            weight: weight,
            locktime: lockTime,
            vin: ins.map {
                $0.bCoreInput
            },
            vout: outs.enumerated().map { (i, output) in
                output.toBCoreOutput(outIdx: i, network: network)
            },
            hex: data.hex,
            blockhash: .none,
            confirmations: .none,
            time: .none,
            blocktime: .none
        )
    }
}

extension Tx.In {
    var bCoreInput: CoreTx.Input {
        isCoinbase
        ? .init(
            coinbase: scriptSig?.data.hex ?? "",
            scriptSig: .none,
            txid: .none,
            vout: .none,
            txinwitness: witness?.map(\.hex),
            sequence: sequence
        )
        : .init(
            coinbase: .none,
            scriptSig: .init(
                asm: scriptSig?.asm ?? "",
                hex: scriptSig?.data.hex ?? ""
            ),
            txid: txID,
            vout: outIdx,
            txinwitness: witness?.map(\.hex),
            sequence: sequence
        )
    }
}

extension Tx.Out {
    func toBCoreOutput(outIdx: Int, network: Network = .main) -> CoreTx.Output {
        .init(
            value: doubleValue,
            n: outIdx,
            scriptPubKey: .init(
                asm: scriptPubKey.asm,
                desc: "", // TODO: Create descriptor
                hex: scriptPubKey.data.hex,
                address: address(network: network),
                type: .init(rawValue: CoreScriptType(scriptPubKey.scriptType).rawValue) ?? .unknown
            )
        )
    }
}

