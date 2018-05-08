
import UIKit
import NurAPIBluetooth

class MainViewController: UIViewController {

    @IBOutlet weak var readerName: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let reader = Bluetooth.sharedInstance().currentReader else {
            self.readerName.text = "no reader connected"
            return
        }

        self.readerName.text = reader.name ?? reader.identifier.uuidString
    }
}
