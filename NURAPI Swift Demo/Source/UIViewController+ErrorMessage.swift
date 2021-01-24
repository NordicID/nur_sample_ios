
import UIKit
import NurAPIBluetooth

extension UIViewController {

    func checkError(_ code: Int32, message: String) -> Bool {
        let error = NUR_ERRORCODES(rawValue: UInt32(code))
        if error == NUR_NO_ERROR {
            return true
        }

        var buffer = [Int8]()
        buffer.reserveCapacity(256)
        NurApiGetErrorMessage( code, &buffer, 256 )
        let errorMessage = String(cString: buffer)

        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "\(message)\n\(errorMessage)", preferredStyle: .alert)
            alert.addAction( UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        return false
    }
}
