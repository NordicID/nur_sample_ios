
import UIKit
import NurAPIBluetooth

class TagInfoViewController: UITableViewController {

    // the tag we operate on
    var tag: Tag!

    enum InfoType : Int {
        case epc = 0
        case channel
        case rssi
        case timestamp
        case frequency
        case antennaId

        // not used, as it's not valid when streaming?
        case scaledRssi

        var text: String {
            switch self {
            case .epc: return "EPC"
            case .channel: return "Channel"
            case .rssi: return "RSSI "
            case .scaledRssi: return "Scaled RSSI"
            case .timestamp: return "Timestamp"
            case .frequency: return "Frequency"
            case .antennaId: return "Antenna Id"
            }
        }
   }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // match with InfoType
        return 6
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagInfoCell", for: indexPath)

        guard let type = InfoType(rawValue: indexPath.row) else {
            cell.textLabel?.text = "Invalid"
            cell.detailTextLabel?.text = "Invalid"
            return cell
        }

        cell.textLabel?.text = type.text

        switch type {
        case .epc: cell.detailTextLabel?.text = tag.epc
        case .channel: cell.detailTextLabel?.text = "\(tag.channel)"
        case .rssi: cell.detailTextLabel?.text = "\(tag.rssi) dB"
        case .scaledRssi: cell.detailTextLabel?.text = "\(tag.scaledRssi) dB"
        case .timestamp: cell.detailTextLabel?.text = "\(tag.timestamp)"
        case .frequency: cell.detailTextLabel?.text = "\(tag.frequency) Hz"
        case .antennaId: cell.detailTextLabel?.text = "\(tag.antennaId)"
        }

        return cell
    }
}
