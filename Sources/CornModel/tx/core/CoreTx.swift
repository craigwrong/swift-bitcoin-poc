import Foundation

public struct CoreTx: Equatable, Decodable {
    
    public init(txid: String, hash: String, version: UInt32, size: Int, vsize: Int, weight: Int, locktime: UInt32, vin: [CoreTx.Input], vout: [CoreTx.Output], hex: String, blockhash: String?, confirmations: Int?, time: Date?, blocktime: Int?) {
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

    public let txid: String
    public let hash: String
    public let version: UInt32
    public let size: Int
    public let vsize: Int
    public let weight: Int
    public let locktime: UInt32
    public let vin: [Input]
    public let vout: [Output]
    public let hex: String
    public let blockhash: String?
    public let confirmations: Int?
    public let time: Date?
    public let blocktime: Int?
}

public extension CoreTx {
    
    var toBitcoinTransaction: Tx {
        .init(Data(hex: hex))
    }
    
    struct Input: Equatable, Decodable {
        
        public  init(coinbase: String? = nil, scriptSig: CoreTx.Input.UnlockScript? = nil, txid: String? = nil, vout: UInt32? = nil, txinwitness: [String]? = nil, sequence: UInt32) {
            self.coinbase = coinbase
            self.scriptSig = scriptSig
            self.txid = txid
            self.vout = vout
            self.txinwitness = txinwitness
            self.sequence = sequence
        }
        
        
        public struct UnlockScript: Equatable, Decodable {
            public init(asm: String, hex: String) {
                self.asm = asm
                self.hex = hex
            }
            
            public let asm: String
            public let hex: String
        }

        // Either coinbase (scriptsig)
        public let coinbase: String?
        
        // Either scriptsig
        public let scriptSig: UnlockScript?
        public let txid: String?
        public let vout: UInt32?
        
        public let txinwitness: [String]?
        
        public let sequence: UInt32
    }
    
    struct Output: Equatable, Decodable {
        
        public init(value: Double, n: Int, scriptPubKey: CoreTx.Output.LockScript) {
            self.value = value
            self.n = n
            self.scriptPubKey = scriptPubKey
        }
        
        public struct LockScript: Equatable, Decodable {
            
            public init(asm: String, desc: String, hex: String, address: String? = nil, type: CoreTx.Output.LockScript.ScriptType) {
                self.asm = asm
                self.desc = desc
                self.hex = hex
                self.address = address
                self.type = type
            }
            
            public enum ScriptType: String, Equatable, Decodable {
                case witness_v0_keyhash, pubkeyhash, nulldata, unknown
            }
            
            public let asm: String
            public let desc: String
            public let hex: String
            public let address: String?
            public let type: ScriptType
        }
        
        public let value: Double
        public let n: Int
        public let scriptPubKey: LockScript
    }
}

public extension Tx {
    var toBCoreTransaction: CoreTx {
        .init(
            txid: txid,
            hash: wtxid,
            version: version.uInt32,
            size: size,
            vsize: vsize,
            weight: weight,
            locktime: lockTime,
            vin: zip(ins, witnessData).map { (input, witness) in
                input.toBCoreInput(witness: witness)
            },
            vout: outs.enumerated().map { (i, output) in
                output.toBCoreOutput(outIdx: i)
            },
            hex: data.hex,
            blockhash: .none,
            confirmations: .none,
            time: .none,
            blocktime: .none
        )
    }
}

public extension Tx.In {
    func toBCoreInput(witness: Tx.Witness) -> CoreTx.Input {
        isCoinbase
        ? .init(
            coinbase: scriptSig.data(includeLength: false).hex,
            scriptSig: .none,
            txid: .none,
            vout: .none,
            txinwitness: witness.stack.map(\.hex),
            sequence: sequence
        )
        : .init(
            coinbase: .none,
            scriptSig: .init(
                asm: scriptSig.asm,
                hex: scriptSig.data(includeLength: false).hex
            ),
            txid: txID,
            vout: outIdx,
            txinwitness: witness.stack.map(\.hex),
            sequence: sequence
        )
    }
}

public extension Tx.Out {
    func toBCoreOutput(outIdx: Int) -> CoreTx.Output {
        .init(
            value: doubleValue,
            n: outIdx,
            scriptPubKey: .init(
                asm: scriptPubKey.asm,
                desc: "", // TODO: Create descriptor
                hex: scriptPubKey.data(includeLength: false).hex,
                address: address,
                type: .init(rawValue: CoreScriptType(scriptPubKey.scriptType).rawValue) ?? .unknown
            )
        )
    }
}

