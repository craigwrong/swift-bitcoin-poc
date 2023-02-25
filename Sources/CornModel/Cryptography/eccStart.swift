import Foundation
import ECHelper

public func eccStart() {
    cECCStart(getRandBytesWrapped(_:_:))
}

public func eccStop() {
    cECCStop()
}
