
import UIKit
import NurAPIBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BluetoothDelegate {

    var window: UIWindow?
    var selectedReader:CBPeripheral?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        Bluetooth.sharedInstance().register(self)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions 
        // (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application 
        // to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

        //
        //  MARK: - Bluetooth delegate
        //
        func bluetoothStateChanged(_ state: CBCentralManagerState) {
            if state != CBCentralManagerState.poweredOn || Bluetooth.sharedInstance().isScanning {
                // not powered on or already scanning
                print( "appdelegate bluetooth not turned on or already scanning or readers" )
                return
            }
        }

        func readerFound(_ reader: CBPeripheral!, rssi: NSNumber!) {
            print("appdelegate reader found: \(reader.name)" )
        }

        func readerConnectionOk() {
            print( "appdelegate connection ok")
        }

        func readerConnectionFailed() {
            print( "appdelegate connection failed")
        }

        func readerDisconnected() {
            print( "appdelegate disconnected from reader")
            DispatchQueue.main.async {
                Bluetooth.sharedInstance()?.restoreConnection(self.selectedReader?.identifier.uuidString)
            }
        }

        func notificationReceived(_ timestamp: DWORD, type: Int32, data: LPVOID!, length: Int32) {
            print("appdelegate received notification: \(type)")
        }

}

