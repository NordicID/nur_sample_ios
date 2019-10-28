
import UIKit
import NurAPIBluetooth

class SelectReaderViewController: UITableViewController, BluetoothDelegate, LogDelegate {

    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // set up as a delegate
        Bluetooth.sharedInstance().register(self)
        Bluetooth.sharedInstance().logDelegate = self

        // can we start scanning?
        if Bluetooth.sharedInstance().state == CBCentralManagerState.poweredOn {
            // bluetooth is on, start scanning
            Bluetooth.sharedInstance().startScanning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // no longer a delegate
        Bluetooth.sharedInstance().deregister( self )
    }

    //
    //  MARK: - Table view datasource
    //
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
    //  MARK: - Table view delegate
    //
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < Bluetooth.sharedInstance().readers.count else {
            return
        }

        guard let reader = Bluetooth.sharedInstance().readers[indexPath.row] as? CBPeripheral else {
            return
        }
        appDelegate.selectedReader = reader;
        
        if Bluetooth.sharedInstance()?.currentReader == nil {
            print("connecting to reader: \(reader)")
            Bluetooth.sharedInstance().connect(toReader: reader)
        }else {
            print("already connected: \(reader)")
            
            self.performSegue(withIdentifier: "ShowReaderSegue", sender: nil)
            
        }
        

    }

    //
    //  MARK: - Bluetooth delegate
    //
    func bluetoothStateChanged(_ state: CBCentralManagerState) {
        if state != CBCentralManagerState.poweredOn || Bluetooth.sharedInstance().isScanning {
            // not powered on or already scanning
            print( "bluetooth not turned on or already scanning or readers" )
            return
        }

        // call on the main thread
        DispatchQueue.main.async {
            print( "bluetooth state changed: \(state.rawValue)" )
            Bluetooth.sharedInstance().startScanning()
        }
    }

    func readerFound(_ reader: CBPeripheral!, rssi: NSNumber!) {
        // call on the main thread
        DispatchQueue.main.async {
            print("reader found: \(reader.name)" )
            self.tableView.reloadData()
        }
    }

    func readerConnectionOk() {
        print( "connection ok")
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "ShowReaderSegue", sender: nil)
        }
    }

    func readerConnectionFailed() {
        print( "connection failed")
        DispatchQueue.main.async {
        }
    }

    func readerDisconnected() {
        print( "disconnected from reader")
        DispatchQueue.main.async {
        }
    }

    func notificationReceived(_ timestamp: DWORD, type: Int32, data: LPVOID!, length: Int32) {
        print("received notification: \(type)")
    }

    //
    // MARK: - Bluetooth log delegate
    func debug(_ message: String!) {
        print("NurAPI: \(message!)")
    }
}

