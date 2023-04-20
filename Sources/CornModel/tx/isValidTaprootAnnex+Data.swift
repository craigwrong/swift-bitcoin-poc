import Foundation

extension Data {
    var isValidTaprootAnnex: Bool {
        if let firstByte = first {
            return firstByte == 0x50
        }
        return false
    }
}
