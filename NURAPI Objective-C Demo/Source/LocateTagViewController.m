
#import "LocateTagViewController.h"
#import "LocateTagAntennaSelector.h"
#import "SmoothingBuffer.h"
#import "UIButton+BackgroundColor.h"

@interface LocateTagViewController () {
    unsigned char epc[NUR_MAX_EPC_LENGTH];
    unsigned int epcLength;
}

@property (nonatomic, strong) dispatch_queue_t           dispatchQueue;
@property (nonatomic, strong) LocateTagAntennaSelector * antennaSelector;
@property (nonatomic, strong) SmoothingBuffer *          smoothingBuffer;

@end

@implementation LocateTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    // antenna selector
    self.antennaSelector = [LocateTagAntennaSelector new];

    // smoothing buffer to make the shown values a bit more calm
    self.smoothingBuffer = [[SmoothingBuffer alloc] initWithSize:5];
}


- (void) viewWillAppear:(BOOL)animated {
    self.tagLabel.text = self.tag.hex;
    [self.actionButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];

    // copy the tag to more permanent storage
    epcLength = (unsigned int)self.tag.epc.length;
    memcpy( epc, self.tag.epc.bytes, epcLength );

    [super viewWillAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

    // do we have a tag? if so start locating automatically
    if (self.tag ) {
        [self toggleLocating];
    }
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // stop locating
    if ( [Bluetooth sharedInstance].currentReader ) {
        [self stopLocating];
    }
}


- (void) showErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    NSLog( @"NURAPI error: %@", message );

    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // nothing special to do right now
                               }];


    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction) toggleLocating {
    // the reader can have disconnected while we were locating
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        self.progressView.percent = 0;
        return;
    }

    dispatch_async(self.dispatchQueue, ^{
        if ( NurApiIsTraceRunning( [Bluetooth sharedInstance].nurapiHandle ) ) {
            [self stopLocating];
        }
        else {
            [self startLocating];
        }
    } );
}


- (void) startLocating {
    NSLog( @"starting trace stream" );

    dispatch_async( self.dispatchQueue, ^{
        // setup antennas for tracing
        int error = [self.antennaSelector begin];
        if ( error != NUR_NO_ERROR ) {
            NSLog( @"failed to setup antennas for tracing" );

            // show the error or update the button label on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showErrorMessage:error];
            } );

            return;
        }

        struct NUR_TRACETAG_DATA response;

        // request continuous tracing
        BYTE flags = NUR_TRACETAG_NO_EPC | NUR_TRACETAG_START_CONTINUOUS;
        error = NurApiTraceTagByEPC( [Bluetooth sharedInstance].nurapiHandle, epc, epcLength, flags, &response );

        NSLog( @"stream result: %d", error );

        // show the error or update the button label on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.actionButton setTitle: @"Stop" forState: UIControlStateNormal];

            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to start trace stream" );
                [self showErrorMessage:error];
                return;
            }
        } );
    } );
}


- (void) stopLocating {
    NSLog( @"stopping trace stream" );

    dispatch_async(self.dispatchQueue, ^{
        int error = NurApiStopContinuous( [Bluetooth sharedInstance].nurapiHandle );

        // show the error or update the button label on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.actionButton setTitle: @"Start" forState: UIControlStateNormal];

            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to stop trace stream" );
                [self showErrorMessage:error];
                return;
            }
        } );

        // reset the antenna selector to what it was before tracing started
        [self.antennaSelector stop];
    } );
}



//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {

    switch ( type ) {
        case NUR_NOTIFICATION_TRACETAG: {
            const struct NUR_TRACETAG_DATA *traceData = (const struct NUR_TRACETAG_DATA *)data;

            self.tag.scaledRssi = (char)[self.antennaSelector adjust:traceData->scaledRssi];
            NSLog( @"trace event, rssi: %d, scaled rssi: %d, adjusted rssi: %d, antenna id: %d", traceData->rssi, traceData->scaledRssi, self.tag.scaledRssi, traceData->antennaId );

            // smooth the shown value a bit
            int smoothedValue = [self.smoothingBuffer add:self.tag.scaledRssi];

            // update the % label
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.percent = smoothedValue;
            } );
        }
            break;

            // trigger pressed or released?
        case NUR_NOTIFICATION_IOCHANGE: {
            struct NUR_IOCHANGE_DATA *iocData = (struct NUR_IOCHANGE_DATA *)data;
            if (iocData->source == NUR_ACC_TRIGGER_SOURCE) {
                NSLog( @"trigger changed, dir: %d", iocData->dir );
                if (iocData->dir == 0) {
                    [self toggleLocating];
                }
            }
        }
            break;

        default:
            break;        
    }
}

@end
