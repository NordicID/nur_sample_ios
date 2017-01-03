
#import <NurAPIBluetooth/Bluetooth.h>

#import "ConnectionManager.h"

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


- (void) applicationTerminating {
    [[Bluetooth sharedInstance] disconnectFromReader];
}


- (void) applicationActivated {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * uuid = [defaults objectForKey:@"lastUuid"];
    if ( uuid ) {
        // we have a device that we were last connected to, restore that connection
        NSLog( @"previously connected to device: %@", uuid );

        // attempt to restore the connection
        [[Bluetooth sharedInstance] restoreConnection:uuid];
    }
}


- (void) applicationDeactivated {
    // save the id of the current reader in user defaults so that we can later check for it when we're resumed
    CBPeripheral * currentReader = [Bluetooth sharedInstance].currentReader;
    if ( currentReader ) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSString * uuid = currentReader.identifier.UUIDString;
        [defaults setObject:uuid forKey:@"lastUuid"];
        [defaults synchronize];

        NSLog( @"saving currently connected device uuid: %@", uuid );

        // disconnect and release the reader
        [[Bluetooth sharedInstance] disconnectFromReader];
    }
}

@end
