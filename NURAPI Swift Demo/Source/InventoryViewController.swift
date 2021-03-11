
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
                        self.inventoryButton.setTitle("Stop", for: UIControl.State.normal)
                    }
                }
            }
            else {
                NSLog("stopping inventory stream")
                if self.checkError( NurApiStopInventoryStream(handle), message: "Failed to stop inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        self.inventoryButton.setTitle("Start", for: UIControl.State.normal)
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

        defer {
            let streamData = UnsafePointer<NUR_INVENTORYSTREAM_DATA>(streamDataPtr).pointee

            // restart stream if it stopped
            if streamData.stopped.boolValue {
                if checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session), message: "Failed to start inventory stream") {
                    print("stream restarted")
                }
            }
        }

        // first lock the tag storage
        if !checkError(NurApiLockTagStorage(handle, true), message: "Failed to lock tag storage" ) {
            return
        }

        // get number of tags read in this round
        var tagCount: Int32 = 0
        if !checkError(NurApiGetTagCount(handle, &tagCount), message: "Failed to clear tag storage" ) {
            return
        }

        print("tags found: \(tagCount)")

        if tagCount == 0 {
            // if no tags then we're done here
            _ = checkError(NurApiLockTagStorage(handle, false), message: "Failed to lock tag storage" )
            return
        }

        // allocate space to hold the tags and fetch them all at once
        let tagBuffer = UnsafeMutablePointer<NUR_TAG_DATA_EX>.allocate(capacity: Int(tagCount))
        let stride = UInt32(MemoryLayout<NUR_TAG_DATA_EX>.stride)
        let status = checkError(NurApiGetAllTagDataEx(handle, tagBuffer, &tagCount, stride), message: "Failed to fetch tags" )

        for index in 0 ..< Int(tagCount) {
            let tagData = tagBuffer[index]

            // convert the tag data into an array of BYTEs
            withUnsafeBytes(of: tagData.epc) { raw in
                // array with correct length
                let bytes = raw[0 ..< Int(tagData.epcLen)]

                // convert to a hex string
                let epc = bytes.reduce( "", { result, byte in
                    result + String(format:"%02x", byte )
                })

                DispatchQueue.main.async {
                    if !self.tags.contains(where: { $0.epc == epc } ) {
                        // emit a tag to any optional handler
                        let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )

                        self.tags.append(tag)
                        self.tagsFoundLabel.text = String(self.tags.count)
                        self.tableView.reloadData()
                    }
                }
            }
        }
                //bytes.map{ UInt8($0) }
//                raw.bindMemory(to: UInt8.self)
//                let bytes = Array(raw)

//            withUnsafe Pointer(to: tagData.epc) { ptr in
//                for f in ptr {}
//
//                let buf = UnsafeBufferPointer(start: ptr, count: Int(tagData.epcLen))
//                let bytes = Array(buf)
//                print(bytes)
//            }

//                buf.withMemoryRebound(to: [UInt8].self) { epcData in
//                    let bytes = Array(epcData)
//
//                    // create a hex string from the bytes
//                    let epc = bytes.reduce( "", { result, byte in
//                        result + String(format:"%02x", byte )
//                    })
//
//                    // emit a tag to any optional handler
//                    let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )
//
//                    // update the loca tags
//                    DispatchQueue.main.async {
//                        self.tags.append(tag)
//                        self.tagsFoundLabel.text = String(self.tags.count)
//                        self.tableView.reloadData()
//                    }
//                }
//            }
//            let buf = UnsafeBufferPointer(start: &tagData.epc.0, count: Int(tagData.epcLen))
//            let bytes: [UInt8] = Array(buf.map({ UInt8($0) }))
//
//            // create a hex string from the bytes
//            let epc = bytes.reduce( "", { result, byte in
//                result + String(format:"%02x", byte )
//            })
//
//            // emit a tag to any optional handler
//            let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )
//            DispatchQueue.main.async {
//                self.tags.append(tag)
//                self.tagsFoundLabel.text = String(self.tags.count)
//                self.tableView.reloadData()
//            }


        // clear all tags
        _ = checkError(NurApiClearTags(handle), message: "Failed to clear tag storage" )
        _ = checkError(NurApiLockTagStorage(handle, false), message: "Failed to unlock tag storage" )

        tagBuffer.deallocate()

        // if we failed to get tags then we're done here
        if !status {
            return
        }

        print("tags fetched")


//        if !checkError(NurApiLockTagStorage(handle, true), message: "Failed to lock tag storage" ) {
//            return
//        }
//
//        // read all found tags
//        var tagData = NUR_TAG_DATA()
//        for index in 0 ..< tagCount {
//            if !checkError( NurApiGetTagData(handle, index, &tagData ), message: "Failed to fetch tag \(index)/\(tagCount)") {
//                // failed to fetch tag
//                return
//            }
//
//
//            // convert the tag data into an array of "bytes"
//            let buf = UnsafeBufferPointer(start: &tagData.epc.0, count: Int(tagData.epcLen))
//            let bytes: [UInt8] = Array(buf.map({ UInt8($0) }))
//
//            // create a hex string from the bytes
//            let epc = bytes.reduce( "", { result, byte in
//                result + String(format:"%02x", byte )
//            })
//
//            // emit a tag to any optional handler
//            let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )
//            DispatchQueue.main.async {
//                self.tags.append(tag)
//                self.tagsFoundLabel.text = String(self.tags.count)
//                self.tableView.reloadData()
//            }
//        }
    }
}
