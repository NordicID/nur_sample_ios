
#import "NURAPI.h"
#import "NurAccessoryExtension.h"

#import <CoreBluetooth/CoreBluetooth.h>


/**
 * Bluetooth delegate protocol.
 *
 * This protocol must be implemented by all classes the intend to receive state change callbacks from the
 * Bluetooth class.
 *
 * Note that the notifications may not be running on the main UI thread and it is up to the receiver to
 * use the correct thread if doing for instance UI updates.
 *
 * All methods are optional.
 **/
@protocol BluetoothDelegate <NSObject>

@optional

/**
 * Callback for when the Bluetooth subsystem has changed state. When receiving the CBCentralManagerStatePoweredOn state
 * it is safe to start scanning for devices. If the scanning is started too early it will either trigger a system warning
 * or be silently ignored by the Bluetooth stack.
 **/
- (void) bluetoothStateChanged:(CBCentralManagerState)state;

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
 * Notification callback from NurAPI. This callback gets called on a NurAPI thread for various notifications
 * and events. For instance tag and barcode scanning trigger notifications. See the NurAPI documentation for further
 * information about the notification types and data.
 *
 * @param timestamp the timestamp for the notification.
 * @param type the type of the notificiation.
 * @param data raw notification data.
 * @param length the length in bytes of the raw data.
 *
 * @sa enum NUR_NOTIFICATION, NotificationCallback
 *
 **/
- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length;

@end


/**
 * Main Bluetooth interface. Handles scanning for RFID readers and initializes the low level connection to NurAPI. 
 * This class is built on the normal CoreBluetooth framework which is used to perform all scanning and basic
 * Bluetooth actions. This class does not handle any of the RFID communication, that is taken care of by NurAPI,
 * the role of this class is to facilitate the connection to NurAPI and provide a bridge between the I/O operations
 * of CoreBluetooth and NurAPI.
 *
 * In order to use this class register a delegate that implements the BluetoothDelegate protocol in order to 
 * receive notifications of any kind of high level scanning events. There can be many delegates registered at the
 * same time, e.g. different UI views.
 *
 * This class is limited to only one simultaneous reader connection.
 *
 * @see BluetoothDelegate
 **/
@interface Bluetooth : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 * YES if a scan for readers is currently in progress and NO if not.
 **/
@property (nonatomic, readonly) BOOL isScanning;

/**
 * All currently known RFID readers, updated when startScanning is called.
 **/
@property (nonatomic, strong, readonly) NSMutableArray * readers;

/**
 * The current connected reader. Set when connectToReader: is called.
 **/
@property (nonatomic, weak, readonly) CBPeripheral * currentReader;

/**
 * The current state of the Bluetooth stack. This is the same value sent to the bluetoothStateChanged: delegate
 * method.
 **/
@property (nonatomic, readonly) CBCentralManagerState state;

/**
 * The low level NurAPI handle. Use this with all NurAPI calls. This is set once a connection to a
 * device has been successfully initialized. When the delegate callback readerConnectionOk is called
 * this handle is valid and can be used.
 **/
@property (nonatomic, assign, readonly) void * nurapiHandle;

/**
 * Global singleton accessor method. Use this to access all the functionality provided by this API.
 *
 * @return singleton instance.
 **/
+ (Bluetooth *) sharedInstance;

/**
 * Registers @p delegate as a delegate for scanning related events. The same delegate will only
 * be registered once, it is no error to register the same delegate twice. A strong reference is kept to
 * the delegate, so make sure to deregister your delegate when it's no longer needed.
 *
 * @param delegate the delegate to register.
 **/
- (void) registerDelegate:(id<BluetoothDelegate>)delegate;

/**
 * Deregisters the given @p delegate. If a delegate is not deregistered it will be retained by this class.
 * This method can safely be called several times for the same delegate.
 *
 * @param delegate the delegate to deregister.
 **/
- (void) deregisterDelegate:(id<BluetoothDelegate>)delegate;

/**
 * Starts a Bluetooth scan for RFID readers. The scan only looks for readers with a particular global service UUID.
 * When a reader is found the readerFound: delegate callback is called once for each found device. 
 * If there are already connected readers then the delegate callback is called immediately for each device.
 **/
- (void) startScanning;

/**
 * Stops scanning for devices. This should be called once a suitable device has been found and the connection to the
 * device has been initialized in order to save power.
 **/
- (void) stopScanning;

/**
 * Attempts to connect to the given @p reader. If successful the readerConnectionOk delegate callback will be called.
 * If the connection fails then readerConnectionFailed is called. The @p reader will be stored in the property currentReader.
 * Any previous connected reader is first disconnected, i.e. there can be only one connected reader at any given time.
 *
 * @param reader the reader to connect to.
 **/
- (void) connectToReader:(CBPeripheral *)reader;

/**
 * Disconnects from the current reader.
 **/
- (void) disconnectFromReader;

@end
