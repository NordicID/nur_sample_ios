
import UIKit
import NurAPIBluetooth

class SelectReaderViewController: UITableViewController, BluetoothDelegate {

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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Bluetooth.sharedInstance().readers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: "ReaderCell" )! as UITableViewCell

        // get the associated reader
        let reader : CBPeripheral = Bluetooth.sharedInstance().readers.object(at: indexPath.row ) as! CBPeripheral

        cell.textLabel?.text = reader.name
        cell.detailTextLabel?.text = reader.identifier.uuidString
        return cell
    }
    

    //
    // Bluetooth Delegate
    //
    func bluetoothStateChanged(_ state: CBCentralManagerState) {
        if state != CBCentralManagerState.poweredOn || Bluetooth.sharedInstance().isScanning {
            // not powered on or already scanning
            print( "bluetooth not turned on or already scanning or readers" )
            return
        }

        // call on the main thread
        DispatchQueue.main.async {
            print( "bluetooth state changed: \(state)" )
            Bluetooth.sharedInstance().startScanning()
        }
    }

    func readerFound(_ reader: CBPeripheral!) {
        // call on the main thread
        DispatchQueue.main.async {
            print("reader found: \(reader.name)" )
            self.tableView.reloadData()
        }
    }
}

