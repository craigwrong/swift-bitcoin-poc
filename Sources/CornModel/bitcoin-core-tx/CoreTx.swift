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
    
    var toBitcoinTransaction: Transaction {
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
            
            init(asm: String, desc: String, hex: String, address: String? = nil, type: LockType) {
                self.asm = asm
                self.desc = desc
                self.hex = hex
                self.address = address
                self.type = type
            }
            
            enum LockType: String, Equatable, Decodable {
                case nonStandard = "nonstandard",
                     pubKey = "pubkey",
                     pubKeyHash = "pubkeyhash",
                     scriptHash = "scripthash",
                     multiSig = "multisig",
                     nullData = "nulldata",
                     witnessV0KeyHash = "witness_v0_keyhash",
                     witnessV0ScriptHash = "witness_v0_scripthash",
                     witnessV1TapRoot = "witness_v1_taproot",
                     witnessUnknown = "witness_unknown",
                     unknown
            }
            
            let asm: String
            let desc: String
            let hex: String
            let address: String?
            let type: LockType
        }
        
        let value: Double
        let n: Int
        let scriptPubKey: LockScript
    }
}

extension Transaction {
    func toBCoreTransaction(network: Network = .main) -> CoreTx {
        .init(
            txid: txid,
            hash: wtxid,
            version: version.rawValue,
            size: size,
            vsize: vsize,
            weight: weight,
            locktime: locktime.rawValue,
            vin: inputs.map {
                $0.bCoreInput
            },
            vout: outputs.enumerated().map { (i, output) in
                output.toBCoreOutput(outputIndex: i, network: network)
            },
            hex: data.hex,
            blockhash: .none,
            confirmations: .none,
            time: .none,
            blocktime: .none
        )
    }
}

extension Transaction.Input {
    var bCoreInput: CoreTx.Input {
        let decodedScript = ParsedScript(script.data)!
        return isCoinbase
        ? .init(
            coinbase: script.data.hex,
            scriptSig: .none,
            txid: .none,
            vout: .none,
            txinwitness: witness?.elements.map(\.hex),
            sequence: sequence.rawValue
        )
        : .init(
            coinbase: .none,
            scriptSig: .init(
                asm: decodedScript.asm,
                hex: script.data.hex
            ),
            txid: outpoint.transaction,
            vout: outpoint.output,
            txinwitness: witness?.elements.map(\.hex),
            sequence: sequence.rawValue
        )
    }
}

extension Transaction.Output {

    func toBCoreOutput(outputIndex: Int, network: Network = .main) -> CoreTx.Output {
        let decodedScript = ParsedScript(script.data)!
        return .init(
            value: doubleValue,
            n: outputIndex,
            scriptPubKey: .init(
                asm: decodedScript.asm,
                desc: "", // TODO: Create descriptor
                hex: script.data.hex,
                address: address(network: network),
                type: .init(rawValue: CoreTx.Output.LockScript.LockType(decodedScript.outputType).rawValue) ?? .unknown
            )
        )
    }

    var doubleValue: Double {
        Double(value) / 100_000_000
    }
    
    func address(network: Network = .main) -> String {
        if script.outputType == .witnessV0KeyHash || script.outputType == .witnessV0ScriptHash {
            return (try? SegwitAddrCoder(bech32m: false).encode(hrp: network.bech32HRP, version: 0, program: script.witnessProgram)) ?? ""
        } else if script.outputType == .witnessV1TapRoot {
            return (try? SegwitAddrCoder(bech32m: true).encode(hrp: network.bech32HRP, version: 1, program: script.witnessProgram)) ?? ""
        }
        return ""
    }
}

extension CoreTx.Output.LockScript.LockType {
    
    init(_ scriptType: OutputType) {
        switch scriptType {
        case .nonStandard:
            self = .nonStandard
        case .pubKey:
            self = .pubKey
        case .pubKeyHash:
            self = .pubKeyHash
        case .scriptHash:
            self = .scriptHash
        case .multiSig:
            self = .multiSig
        case .nullData:
            self = .nullData
        case .witnessV0KeyHash:
            self = .witnessV0KeyHash
        case .witnessV0ScriptHash:
            self = .witnessV0ScriptHash
        case .witnessV1TapRoot:
            self = .witnessV1TapRoot
        case .witnessUnknown:
            self = .witnessUnknown
        }
    }
}
