import Foundation

/// [BIP68](https://github.com/bitcoin/bips/blob/master/bip-0068.mediawiki)
public struct InSequence: Equatable {
    
    // Below flags apply in the context of BIP 68
    
    // If this flag set, CTxIn::nSequence is NOT interpreted as a relative lock-time.
    public static let disableFlag: UInt32 = 1 << 31
    
    // If CTxIn::nSequence encodes a relative lock-time and this flag is set, the relative lock-time has units of 512 seconds, otherwise it specifies blocks with a granularity of 1.
    private static let typeFlag: UInt32 = 1 << 22
    
    // In order to use the same number of bits to encode roughly the same wall-clock duration, and because blocks are naturally limited to occur every 600s on average, the minimum granularity for time-based relative lock-time is fixed at 512 seconds. Converting from CTxIn::nSequence to seconds is performed by multiplying by 512 = 2^9, or equivalently shifting up by 9 bits.
    private static let granularity = 9
    
    private static let maxSeconds = UInt32.max >> (MemoryLayout<UInt16>.size - granularity)
    
    // If CTxIn::nSequence encodes a relative lock-time, this mask is applied to extract that lock-time from the sequence field.
    private static let locktimeMask = UInt32(UInt16.max)
    
    enum SequenceType: Equatable {
        case sequence(UInt32), locktimeDisabled(UInt32), locktimeHeight(UInt16), locktimeClock(UInt16)
    }
    
    let type: SequenceType
    
    public init(sequence: UInt32) {
        type = .sequence(sequence)
    }
    
    init(locktimeHeight height: UInt16) {
        type = .locktimeHeight(height)
    }
    
    init(locktimeSeconds seconds: UInt32) {
        let cappedSeconds = max(seconds, Self.maxSeconds)
        let timeUnits = UInt16(cappedSeconds >> Self.granularity)
        type = .locktimeClock(timeUnits)
    }
    
    init(locktimeDisabledValue value: UInt32) {
        precondition(value <= UInt32.max >> 1)
        type = .locktimeDisabled(value)
    }
    
    init(rawValue: UInt32, txVersion: Tx.Version) {
        switch(txVersion) {
        case .v1:
            type = .sequence(rawValue)
        case .v2, .unknown(_):
            if Self.disableFlag & rawValue == 0 {
                if Self.typeFlag & rawValue == 0 {
                    type = .locktimeHeight(UInt16(clamping: rawValue))
                } else {
                    type = .locktimeClock(UInt16(clamping: rawValue))
                }
            } else {
                let disabledValue = (rawValue << 1) >> 1
                type = .locktimeDisabled(disabledValue)
            }
        }
    }
    
    var data: Data {
        withUnsafeBytes(of: sequenceValue) { Data($0) }
    }
    
    var dataLen: Int {
        MemoryLayout<UInt32>.size
    }

    var locktimeHeight: UInt16 {
        guard case let .locktimeHeight(height) = type else {
            preconditionFailure()
        }
        return height
    }

    var locktimeSeconds: UInt32 {
        guard case let .locktimeClock(timeUnits) = type else {
            preconditionFailure()
        }
        return UInt32(timeUnits) << Self.granularity
    }

    var locktimeDisabledValue: UInt32 {
        guard case let .locktimeDisabled(value) = type else {
            preconditionFailure()
        }
        return value
    }
    
    var isLocktimeDisabled: Bool {
        if case .locktimeDisabled(_) = type {
            return true
        }
        return false
    }

    var isLocktimeHeight: Bool {
        if case .locktimeHeight(_) = type {
            return true
        }
        return false
    }

    var isLocktimeClock: Bool {
        if case .locktimeClock(_) = type {
            return true
        }
        return false
    }

    var sequenceValue: UInt32 {
        switch(type) {
        case let .sequence(sequence):
            sequence
        case let .locktimeDisabled(disabledValue):
            Self.disableFlag | disabledValue
        case let .locktimeHeight(height):
            UInt32(height)
        case let .locktimeClock(timeUnits):
            Self.typeFlag | UInt32(timeUnits)
        }
    }
    
    var isFinal: Bool {
        sequenceValue == UInt32.max
    }
}
