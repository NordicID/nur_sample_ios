
#import <Foundation/Foundation.h>
#import <NurAPIBluetooth/Bluetooth.h>

typedef enum {
    kAlwaysReconnect, // always reconnect to the last device, even when restarting the application
    kNeverReconnect, // only reconnect within the same session, never when restarting the application
} ReconnectMode;


@protocol ConnectionManagerDelegate <NSObject>

@optional

/**
 * Callback indicating that a connection to the given reader has been initiated. At this point it is not yet usable for any NurAPI
 * calls, wait for readerConnectionOk before interacting with the device.
 *
 * @param reader the reader that is being connected to.
 **/
- (void) connectingToReader:(CBPeripheral *)reader;

/**
*
* Callback indicating that the connection to a reader was successful.
**/
- (void) readerConnectionOk;

/**
 * Callback indicating that a reader has now been disconnected. This is only called if the reader was successfully
 * connected, it is not called if the connection to a reader could not be established.
 **/
- (void) readerDisconnected;

/**
 * Callback indicating that the connection to a reader failed.
 **/
- (void) readerConnectionFailed;
@end


@interface ConnectionManager : NSObject <BluetoothDelegate>

// the current reconnect mode, defaults to kAlwaysReconnect
@property (nonatomic, assign) ReconnectMode reconnectMode;

@property (nonatomic, readonly) CBPeripheral * currentReader;

+ (ConnectionManager *) sharedInstance;

- (void) setup;

/**
 * Registers @p delegate as a delegate for reader related events. The same delegate will only
 * be registered once, it is no error to register the same delegate twice. A strong reference is kept to
 * the delegate, so make sure to deregister your delegate when it's no longer needed.
 *
 * @param delegate the delegate to register.
 **/
- (void) registerDelegate:(id<ConnectionManagerDelegate>)delegate;

/**
 * Deregisters the given @p delegate. If a delegate is not deregistered it will be retained by this class.
 * This method can safely be called several times for the same delegate.
 *
 * @param delegate the delegate to deregister.
 **/
- (void) deregisterDelegate:(id<ConnectionManagerDelegate>)delegate;

/**
 * Should be called when the application is about to terminate. Will disconnect from any reader.
 **/
- (void) applicationTerminating;

/**
 * Should be called when the application is activated, i.e. moved to the foreground and resumed.
 **/
- (void) applicationActivated;

/**
 * Should be called when the application is deactivated, i.e. moved to the background for instance by pressing
 * the home button.
 **/
- (void) applicationDeactivated;

@end
