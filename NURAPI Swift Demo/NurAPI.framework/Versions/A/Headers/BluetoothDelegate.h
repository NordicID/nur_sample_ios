
#import <CoreBluetooth/CoreBluetooth.h>

/**
 * Bluetooth delegate protocol.
 *
 * This protocol must be implemented by all classes the intend to receive state change callbacks from the
 * Bluetooth class.
 *
 * Note that the notifications may not be running on the main UI thread.
 *
 * All methods are optional.
 **/
@protocol BluetoothDelegate <NSObject>

@optional

/**
 * Callback for when the Bluetooth subsystem has been enabled for the application. When receiving this
 * callback it is safe to start scanning for devices.
 **/
- (void) bluetoothTurnedOn;

/**
 * Callback for when a new RFID reader has been found. This is not called for any other types of Bluetooth
 * devices (headsets, keyboards etc), only RFID readers that have the service UUID given in serviceUuid.
 * The found reader may already be connected to the device.
 *
 * @param reader the found RFID reader.
 **/
- (void) readerFound:(CBPeripheral *)reader;

/**
 * Callback indicating that the connection to a reader was successful.
 **/
- (void) readerConnectionOk;

/**
 * Callback indicating that the connection to a reader failed.
 **/
- (void) readerConnectionFailed;

/**
 * Callback indicating that the inventory stream has been stopped, either manually or through
 * a timeout.
 **/
- (void) inventoryStreamStopped;

/**
 * Callback indicating that a new tag has been found. Access the tag using the normal NURAPI calls.
 **/
- (void) tagFound;

@end

