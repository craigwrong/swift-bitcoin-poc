import Foundation

/// Used to represent BIP 341's `default` signature hash type.
extension Optional where Wrapped == HashType {
    
    private var assumed: HashType { .all }

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
