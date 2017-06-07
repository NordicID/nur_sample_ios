
#import <NurAPIBluetooth/Bluetooth.h>

#import "ConnectionManager.h"

@interface ConnectionManager ()

@property (nonatomic, assign) BOOL connectionOk;

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
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) applicationTerminating {
    [[Bluetooth sharedInstance] disconnectFromReader];
}


- (void) applicationActivated {
    // if we have a reader we're happy, do nothing
    if ( [Bluetooth sharedInstance].currentReader ) {
        return;
    }

    // always reconnect
    if ( self.reconnectMode == kAlwaysReconnect ) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSString * uuid = [defaults objectForKey:@"lastUuid"];
        if ( uuid ) {
            NSLog( @"found previously connected to device, uuid: %@, attempting to reconnect", uuid );

            // attempt to restore the connection
            [[Bluetooth sharedInstance] restoreConnection:uuid];
        }
    }

//    else {
//        if ( self.previousUuid ) {
//            // we have a device that we were last connected to, restore that connection
//            NSLog( @"found previously connected to device, uuid: %@, attempting to reconnect", self.previousUuid );
//
//            // attempt to restore the connection
//            [[Bluetooth sharedInstance] restoreConnection:self.previousUuid];
//
//            // make sure we don't do this more than once, so clear the UUID
//            self.previousUuid = nil;
//        }
//    }
}


- (void) applicationDeactivated {
    // save the id of the current reader in user defaults so that we can later check for it when we're resumed
    CBPeripheral * currentReader = [Bluetooth sharedInstance].currentReader;
    if ( currentReader ) {
        if ( self.reconnectMode == kAlwaysReconnect ) {
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            NSString * uuid = currentReader.identifier.UUIDString;
            [defaults setObject:uuid forKey:@"lastUuid"];
            [defaults synchronize];
            NSLog( @"permanently storing currently connected device uuid: %@", uuid );
        }

//        else {
//            self.previousUuid = currentReader.identifier.UUIDString;
//            NSLog( @"saving currently connected device uuid: %@", self.previousUuid );
//        }

        // disconnect and release the reader
        [[Bluetooth sharedInstance] disconnectFromReader];
    }
}

/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 **/
- (void) readerConnectionOk {
    NSLog( @"reader connected, connection ok" );
    self.connectionOk = YES;
}


- (void) readerDisconnected {
    NSLog( @"reader disconnection, connection no longer ok" );
    self.connectionOk = NO;
}


@end
