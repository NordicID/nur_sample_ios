
import UIKit
import NurAPIBluetooth

class InventoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BluetoothDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inventoryButton: UIButton!
    @IBOutlet weak var tagsFoundLabel: UILabel!

    private var tags = [Tag]()

    // default scanning parameters
    private let rounds: Int32 = 0
    private let q: Int32 = 0
    private let session: Int32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up as a delegate
        Bluetooth.sharedInstance().register(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // no longer a delegate
        Bluetooth.sharedInstance().deregister( self )
    }

    @IBAction func toggleInventory(_ sender: Any) {
        guard let handle: HANDLE = Bluetooth.sharedInstance().nurapiHandle else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            if !NurApiIsInventoryStreamRunning(handle) {
                NSLog("starting inventory stream")

                // first clear the tags
                NurApiClearTags( handle )

                if self.checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session ), message: "Failed to start inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        self.inventoryButton.titleLabel?.text = "Stop"
                    }
                }
            }
            else {
                NSLog("stopping inventory stream")
                if self.checkError( NurApiStopInventoryStream(handle), message: "Failed to stop inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        self.inventoryButton.titleLabel?.text = "Start"
                    }
                }
            }
        }
    }

    //
    //  MARK: - Table view datasource
    //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: "TagCell" )! as UITableViewCell

        let tag = tags[indexPath.row]
        cell.textLabel?.text = tag.epc
        return cell
    }

    //
    //  MARK: - Table view delegate
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // push a VC for showing some basic tag info
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TagInfoViewController") as! TagInfoViewController
        vc.tag = tags[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }


    //
    //  MARK: - Bluetooth delegate
    //
    func notificationReceived(_ timestamp: DWORD, type: Int32, data: LPVOID!, length: Int32) {
        print("received notification: \(type)")
        switch NUR_NOTIFICATION(rawValue: UInt32(type)) {
        case NUR_NOTIFICATION_INVENTORYSTREAM:
            handleTag(data: data, length: length)

        default:
            NSLog("received notification: \(type)")
            break
        }
    }

    private func handleTag (data: UnsafeMutableRawPointer?, length: Int32) {
        guard let handle: HANDLE = Bluetooth.sharedInstance().nurapiHandle else {
            return
        }

        guard let streamDataPtr = data?.bindMemory(to: NUR_INVENTORYSTREAM_DATA.self, capacity: Int(length)) else {
            return
        }

        let streamData = UnsafePointer<NUR_INVENTORYSTREAM_DATA>(streamDataPtr).pointee

        var tagCount: Int32 = 0
        if !checkError(NurApiGetTagCount(handle, &tagCount), message: "Failed to get tag count" ) {
            return
        }

        print("tags found: \(tagCount)")

        // read all found tags
        var tagData = NUR_TAG_DATA()
        for index in 0 ..< tagCount {
            if !checkError( NurApiGetTagData(handle, index, &tagData ), message: "Failed to fetch tag \(index)/\(tagCount)") {
                // failed to fetch tag
                return
            }

            // convert the tag data into an array of "bytes"
            let buf = UnsafeBufferPointer(start: &tagData.epc.0, count: Int(tagData.epcLen))
            let bytes: [UInt8] = Array(buf.map({ UInt8($0) }))

            // create a hex string from the bytes
            let epc = bytes.reduce( "", { result, byte in
                result + String(format:"%02x", byte )
            })

            // emit a tag to any optional handler
            let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )
            DispatchQueue.main.async {
                self.tags.append(tag)
                self.tagsFoundLabel.text = String(self.tags.count)
                self.tableView.reloadData()
            }
        }

        NurApiClearTags(handle)

        // restart stream if it stopped
        if streamData.stopped.boolValue {
            if !checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session), message: "Failed to start inventory stream") {
                return
            }

            print("stream restarted")
        }
    }
}
