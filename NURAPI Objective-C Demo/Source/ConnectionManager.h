
#import <Foundation/Foundation.h>
#import <NurAPIBluetooth/Bluetooth.h>

typedef enum {
    kAlwaysReconnect, // always reconnect to the last device, even when restarting the application
    kReconnectSameSession, // only reconnect within the same session, never when restarting the application
} ReconnectMode;

@interface ConnectionManager : NSObject <BluetoothDelegate>

// the current reconnect mode, defaults to kAlwaysReconnect
@property (nonatomic, assign) ReconnectMode reconnectMode;

@property (nonatomic, readonly) CBPeripheral * currentReader;

+ (ConnectionManager *) sharedInstance;

- (void) setup;

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
