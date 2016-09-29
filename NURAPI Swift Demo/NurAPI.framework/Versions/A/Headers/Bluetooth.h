
#import <NurAPI/NURAPI.h>

// undefine __linux__ as NurAPI uses some Linux settings, but CoreBluetooth will
//
#undef __linux__

#import <CoreBluetooth/CoreBluetooth.h>

#import <NurAPI/BluetoothDelegate.h>

/**
 * The UUID used by all RFID readers. Scanning for readers will look for Bluetooth devices
 * with this UUID.
 **/
static NSString * serviceUuid = @"6e400001-b5a3-f393-e0a9-e50e24dcca9e";

/**
 * The UUID of the characteristic of a reader used when sending data to a reader.
 **/
static NSString * transmitUuid = @"6e400003-b5a3-f393-e0a9-e50e24dcca9e";

/**
 * The UUID of the characteristic of a reader used when reading data from a reader.
 **/
static NSString * receiveUuid = @"6e400002-b5a3-f393-e0a9-e50e24dcca9e";


/**
 * Main Bluetooth interface. Handles scanning for RFID readers and initializes the low level connection to NURAPI. 
 * This class is built on the normal CoreBluetooth framework which is used to perform all scanning and basic
 * Bluetooth actions. This class does not handle any of the RFID communication, that is taken care of by NURAPI,
 * the role of this class is to facilitate the connection to NURAPI and provide a bridge between the I/O operations
 * of CoreBluetooth and NURAPI.
 *
 * In order to use this class register a delegate that implements the BluetoothDelegate protocol in order to 
 * receive notifications of any kind of high level scanning events. There can be many delegates registered at the
 * same time.
 
 * Also set a notification function which will receive all NURAPI events. The notification function is a normal C 
 * function and is the main way for NURAPI to inform an application that something has happened.
 *
 * This class is limited to only one simultaneous reader connection.
 *
 * @see BluetoothDelegate
 **/
@interface Bluetooth : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 * All currently known RFID readers, updated when startScanning is called.
 **/
@property (nonatomic, strong, readonly) NSMutableArray * readers;

/**
 * The current connected reader. Set when connectToReader: is called.
 **/
@property (nonatomic, weak, readonly) CBPeripheral * currentReader;

/**
 * The low level NURAPI handle. Use this with all NURAPI calls. This is set once a connection to a
 * device has been successfully initialized. When the delegate callback readerConnectionOk is called
 * this handle is valid and can be used.
 **/
@property (nonatomic, assign, readonly) void * nurapiHandle;

/**
 * Global singleton accessor method.
 *
 * @return singleton instance.
 **/
+ (Bluetooth *) sharedInstance;

/**
 * Registers @p delegate as a delegate for scanning related events. The same delegate will only
 * be registered once.
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
 * Returns all the current delegates that have been registered. The data should be considered as read only.
 *
 * @return all Bluetooth delegates. The set can be empty but is always valid.
**/
- (NSSet *) getDelegates;

/**
 * Starts a Bluetooth scan for RFID readers. The scan only looks for readers with the global serviceUuid service id.
 * When a reader is found the readerFound: delegate callback is called once for each found device. 
 * If there are already connected readers then the delegate callback is called immediately for each device.
 **/
- (void) startScanning;

/**
 * Stops scanning for devices. This is good to call once a suitable device has been found and the connection to the
 * device has been initialized.
 **/
- (void) stopScanning;

/**
 * Attempts to connect to the given @p reader. If successful the readerConnectionOk delegate callback will be called.
 * If the connection fails then readerConnectionFailed is called. The @p reader will be stored in the property currentReader.
 *
 * @param reader the reader to connect to.
 **/
- (void) connectToReader:(CBPeripheral *)reader;

/**
 * Disconnects from any current reader.
 **/
- (void) disconnectFromReader;

@end
