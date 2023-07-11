import Foundation

public enum SighashType: UInt8 {
    case all = 0x01, none = 0x02, single = 0x03, allAnyCanPay = 0x81, noneAnyCanPay = 0x82, singleAnyCanPay = 0x83
    
    init?(_ uInt32: UInt32) {
        self.init(rawValue: UInt8(uInt32))
    }
    
    var isNone: Bool {
        self == .none || self == .noneAnyCanPay
    }

    var isAll: Bool {
        self == .all || self == .allAnyCanPay
    }

    var isSingle: Bool {
        self == .single || self == .singleAnyCanPay
    }

    var isAnyCanPay: Bool {
        self == .allAnyCanPay || self == .noneAnyCanPay || self == .singleAnyCanPay
    }
    
    var data: Data {
        withUnsafeBytes(of: rawValue) { Data($0) }
    }

    var data32: Data {
        withUnsafeBytes(of: UInt32(rawValue)) { Data($0) }
    }
}

/// Used to represent BIP 341's `default` signature hash type.
extension Optional where Wrapped == SighashType {
    
    private var assumed: SighashType { .all }

    var isNone: Bool {
        if case let .some(wrapped) = self {
            return wrapped.isNone
        }
        return assumed.isNone
    }

    var isAll: Bool {
        if case let .some(wrapped) = self {
            return wrapped.isAll
        }
        return assumed.isAll
    }

    var isSingle: Bool {
        if case let .some(wrapped) = self {
            return wrapped.isSingle
        }
        return assumed.isSingle
    }

    var isAnyCanPay: Bool {
        if case let .some(wrapped) = self {
            return wrapped.isAnyCanPay
        }
        return assumed.isAnyCanPay
    }
    
    var data: Data {
        if case let .some(wrapped) = self {
            return wrapped.data
        }
        return withUnsafeBytes(of: UInt8(0)) { Data($0) }
    }
}
