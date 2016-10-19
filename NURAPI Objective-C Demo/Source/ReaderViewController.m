
#import "ReaderViewController.h"
#import "Tag.h"

@interface ReaderViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation ReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog( @"reader: %@", self.reader );

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_queue_create("com.nordicid.bluetooth-demo.nurapi-queue", DISPATCH_QUEUE_SERIAL);

    self.connectedLabel.text = self.reader.identifier.UUIDString;
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

    [self updateBatteryLevel];

    // start a timer that updates the battery level periodically
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // disable the timer
    [self.timer invalidate];
    self.timer = nil;
}


- (void) updateBatteryLevel {
    NSLog( @"checking battery status" );

    dispatch_async(self.dispatchQueue, ^{
        NUR_ACC_BATT_INFO batteryInfo;

        // get current settings
        int error = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));

        dispatch_async(dispatch_get_main_queue(), ^{

            if (error != NUR_NO_ERROR) {
                // failed to get battery info
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
        NSLog( @"connection ok" );
        self.scanButton.enabled = YES;
        self.settingsButton.enabled = YES;
    });
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
