
#import "ReaderViewController.h"
#import "Tag.h"

@interface ReaderViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSTimer * timer;
//@property (nonatomic, assign) BOOL readerOk;

@end


@implementation ReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // assume not ok initially
    //self.readerOk = NO;

    //NSLog( @"using reader: %@", self.reader );

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

    // connection already ok?
    if ( !self.timer ) {
        // start a timer that updates the battery level periodically
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateStatusInfo) userInfo:nil repeats:YES];
    }

    [self updateStatusInfo];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // disable the timer
    if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


- (void) updateStatusInfo {
    [self updateConnectedLabel];
    [self updateBatteryLevel];
}


- (void) updateConnectedLabel {
    CBPeripheral * reader = [Bluetooth sharedInstance].currentReader;

    if ( reader ) {
        self.connectedLabel.text = reader.identifier.UUIDString;
    }
    else {
        self.connectedLabel.text = @"no";
    }
}


- (void) updateBatteryLevel {
    NSLog( @"checking battery status" );

    // any current reader?
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        self.batteryLabel.text = @"?";
        return;
    }

    dispatch_async(self.dispatchQueue, ^{
        NUR_ACC_BATT_INFO batteryInfo;

        // get current settings
        int error = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));

        dispatch_async(dispatch_get_main_queue(), ^{
            // the percentage is -1 if unknown
            if (error != NUR_NO_ERROR ) {
                // failed to get battery info
                char buffer[256];
                NurApiGetErrorMessage( error, buffer, 256 );
                NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
                NSLog( @"failed to get battery info: %@", message );
                self.batteryLabel.text = @"E";
            }
            else if ( batteryInfo.percentage == -1 ) {
                self.batteryLabel.text = @"?";
            }
            else {
                self.batteryLabel.text = [NSString stringWithFormat:@"%d%%", batteryInfo.percentage];
            }
        });
    });
}

/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 * The callbacks do not necessarily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
- (void) readerConnectionOk {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection ok, handle: %p", [Bluetooth sharedInstance].nurapiHandle );
        //self.readerOk = YES;
        self.scanButton.enabled = YES;
        self.settingsButton.enabled = YES;

        // start a timer that updates the battery level periodically
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
    });

    [self updateStatusInfo];
}


- (void) readerConnectionFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection failed" );
        self.scanButton.enabled = NO;
        self.settingsButton.enabled = NO;
        self.writeTagButton.enabled = NO;
        self.infoButton.enabled = NO;
        self.readBarcodeButton.enabled = NO;
    });
}



@end
