import Foundation
import UIKit

enum DeviceIdentifier {
    static func get() -> String {
        let key = "mm_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}

