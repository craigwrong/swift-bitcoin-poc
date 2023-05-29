import Foundation

public struct SigMsgV1Cache {
    public init(shaPrevouts: Data? = nil, shaPrevoutsUsed: Bool = false, shaAmounts: Data? = nil, shaAmountsUsed: Bool = false, shaScriptPubKeys: Data? = nil, shaScriptPubKeysUsed: Bool = false, shaSequences: Data? = nil, shaSequencesUsed: Bool = false, shaOuts: Data? = nil, shaOutsUsed: Bool = false) {
        self.shaPrevouts = shaPrevouts
        self.shaPrevoutsUsed = shaPrevoutsUsed
        self.shaAmounts = shaAmounts
        self.shaAmountsUsed = shaAmountsUsed
        self.shaScriptPubKeys = shaScriptPubKeys
        self.shaScriptPubKeysUsed = shaScriptPubKeysUsed
        self.shaSequences = shaSequences
        self.shaSequencesUsed = shaSequencesUsed
        self.shaOuts = shaOuts
        self.shaOutsUsed = shaOutsUsed
    }
    
    public internal(set) var shaPrevouts: Data?
    public internal(set) var shaPrevoutsUsed: Bool = false
    public internal(set) var shaAmounts: Data?
    public internal(set) var shaAmountsUsed: Bool = false
    public internal(set) var shaScriptPubKeys: Data?
    public internal(set) var shaScriptPubKeysUsed: Bool = false
    public internal(set) var shaSequences: Data?
    public internal(set) var shaSequencesUsed: Bool = false
    public internal(set) var shaOuts: Data?
    public internal(set) var shaOutsUsed: Bool = false
}
