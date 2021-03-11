
import Foundation

struct Tag : CustomDebugStringConvertible, Comparable {

    let epc: String
    let rssi: Int8
    let scaledRssi: Int8
    let antennaId: UInt8
    let timestamp: UInt16
    let frequency: UInt32
    let channel: UInt8

    var debugDescription: String {
        return "[Tag \(epc)]"
    }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.epc == rhs.epc
    }
}
