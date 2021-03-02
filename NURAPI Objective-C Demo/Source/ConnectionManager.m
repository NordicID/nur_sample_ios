
#import <NurAPIBluetooth/Bluetooth.h>

#import "ConnectionManager.h"
#import "Log.h"

@interface ConnectionManager ()

@property (nonatomic, assign) BOOL             setupPerformed;
@property (nonatomic, assign) BOOL             connectionOk;
@property (nonatomic, strong) NSMutableSet *   delegates;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@implementation ConnectionManager

+ (ConnectionManager *) sharedInstance {
    static ConnectionManager * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[ConnectionManager alloc] init];
    });

    // return the instance
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.connectionOk = NO;
        self.setupPerformed = NO;
        self.delegates = [NSMutableSet set];
        self.deviceSupportsBarcodes = YES;

        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        if ( [defaults objectForKey:@"reconnectMode"] ) {
            // set the value without goinf through a setter to avoid triggering saving the value
            _reconnectMode = (ReconnectMode)[defaults integerForKey:@"reconnectMode"];
        }
        else {
            // default to always automatic reconnects
            self.reconnectMode = kAlwaysReconnect;

            // save for future sessions
            [defaults setObject:[NSNumber numberWithInt:(int)self.reconnectMode] forKey:@"reconnectMode"];
            [defaults synchronize];
        }

        // set up the queue used to async any NURAPI calls
        self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
    }

    return self;
}


- (CBPeripheral *) currentReader {
    if ( self.connectionOk ) {
        return [Bluetooth sharedInstance].currentReader;
    }

    // connection to the reader not yet ok
    return nil;
}


- (void) setReconnectMode:(ReconnectMode)reconnectMode {
    _reconnectMode = reconnectMode;

    // save for the future too
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:(int)reconnectMode] forKey:@"reconnectMode"];
    [defaults synchronize];

    // if no automatic reconnection then cancel any reconnection that may have been set already
    if ( reconnectMode == kNeverReconnect ) {
        [[Bluetooth sharedInstance] cancelRestoreConnection];
    }
}


- (void) setup {
    if ( self.setupPerformed ) {
        return;
    }

    // verbose logging by default
    NurApiSetLogLevel( [Bluetooth sharedInstance].nurapiHandle, NUR_LOG_ALL );

    [[Bluetooth sharedInstance] registerDelegate:self];
    self.setupPerformed = YES;
}


//*****************************************************************************************************************
#pragma mark - Delegate handling

- (void) registerDelegate:(id<ConnectionManagerDelegate>)delegate {
    if ( ! [self.delegates containsObject:delegate] ) {
        [self.delegates addObject:delegate];
    }
}


- (void) deregisterDelegate:(id<ConnectionManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}


- (NSSet *) getDelegates {
    return self.delegates;
}


- (void) applicationTerminating {
    [[Bluetooth sharedInstance] disconnectFromReader];
}


- (void) applicationActivated {
    // if setup hasn't been done yet then do nothing. This will be called once when the application window initially becomes active
    // from the AppDelegate and this check avoids connecting before any EULA or similar has been accepted
    if ( !self.setupPerformed ) {
        return;
    }

    // if we have a reader we're happy, do nothing
    if ( [Bluetooth sharedInstance].currentReader ) {
        return;
    }

    // always reconnect
    if ( self.reconnectMode == kAlwaysReconnect ) {
        NSString * uuid = [self getLastConnectedUuid];
        if ( uuid ) {
            logDebug( @"found previously connected to device, uuid: %@, attempting to reconnect", uuid );

            // attempt to restore the connection
            [[Bluetooth sharedInstance] restoreConnection:uuid];
        }
    }
}


- (void) applicationDeactivated {
    // save the id of the current reader in user defaults so that we can later check for it when we're resumed
    CBPeripheral * currentReader = [Bluetooth sharedInstance].currentReader;
    if ( currentReader ) {
        if ( self.reconnectMode == kAlwaysReconnect ) {
            [self setLastConnectedUuid:currentReader.identifier.UUIDString];
        }

        // disconnect and release the reader
        [[Bluetooth sharedInstance] disconnectFromReader];
    }
}


- (NSString *) getLastConnectedUuid {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"lastUuid"];
}


- (void) setLastConnectedUuid:(NSString *)uuid {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:uuid forKey:@"lastUuid"];
    [defaults synchronize];

    logDebug( @"permanently stored currently connected device uuid: %@", uuid );
}


/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 **/
- (void) connectingToReader:(CBPeripheral *)reader {
    logDebug( @"connecting to reader: %@", reader.name );

    // inform all delegates
    NSSet * copiedDelegates = [[NSSet alloc] initWithSet:self.delegates];
    for ( id<BluetoothDelegate> delegate in copiedDelegates ) {
        if ( delegate && [delegate respondsToSelector:@selector(connectingToReader:)] ) {
            [delegate connectingToReader:reader];
        }
    }
}


- (void) readerConnectionOk {
    logDebug( @"reader connected, connection ok" );
    self.connectionOk = YES;

    [self setLastConnectedUuid:[Bluetooth sharedInstance].currentReader.identifier.UUIDString];

    // do some querying about the reader to find needed info, and then inform all delegates
    dispatch_async(self.dispatchQueue, ^{
        NUR_ACC_CONFIG config;

        // get current settings
        int error = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &config, sizeof(NUR_ACC_CONFIG) );
        if (error == NUR_NO_ERROR) {
            self.deviceSupportsBarcodes = (config.config & DEV_FEATURE_IMAGER) ? YES : NO;
        }
        else {
            logError(@"failed to read accessory config");
            // assume it supports...
            self.deviceSupportsBarcodes = YES;
        }
        logDebug(@"device supports barcode reading: %d", self.deviceSupportsBarcodes);

        dispatch_async(dispatch_get_main_queue(), ^{
            // inform all delegates
            NSSet * copiedDelegates = [[NSSet alloc] initWithSet:self.delegates];
            for ( id<BluetoothDelegate> delegate in copiedDelegates ) {
                if ( delegate && [delegate respondsToSelector:@selector(readerConnectionOk)] ) {
                    [delegate readerConnectionOk];
                }
            }
        });
    });


    // stop scanning
    [[Bluetooth sharedInstance] stopScanning];
}


- (void) readerDisconnected {
    logDebug( @"reader disconnected, connection no longer ok" );
    self.connectionOk = NO;

    // inform all delegates
    NSSet * copiedDelegates = [[NSSet alloc] initWithSet:self.delegates];
    for ( id<BluetoothDelegate> delegate in copiedDelegates ) {
        if ( delegate && [delegate respondsToSelector:@selector(readerDisconnected)] ) {
            [delegate readerDisconnected];
        }
    }
}


- (void) readerConnectionFailed {
    self.connectionOk = NO;

    // inform all delegates
    NSSet * copiedDelegates = [[NSSet alloc] initWithSet:self.delegates];
    for ( id<BluetoothDelegate> delegate in copiedDelegates ) {
        if ( delegate && [delegate respondsToSelector:@selector(readerConnectionFailed)] ) {
            [delegate readerConnectionFailed];
        }
    }
}


@end
