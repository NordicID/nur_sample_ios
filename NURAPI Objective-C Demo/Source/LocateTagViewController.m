
#import "LocateTagViewController.h"
#import "UIButton+BackgroundColor.h"

// interval in seconds between the trace passes
#define TRACE_INTERVAL 0.1

@interface LocateTagViewController () {
    unsigned char epc[12];
}

//@property (nonatomic, assign) BOOL      locating;
//@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation LocateTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // not locating yet
    //self.locating = NO;
    //self.timer = nil;
    
    // set up the queue used to async any NURAPI calls
    //self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
    self.dispatchQueue = dispatch_queue_create("com.nordicid.rfiddemo.locate", 0);
}


- (void) viewWillAppear:(BOOL)animated {
    self.tagLabel.text = self.tag.hex;
    [self.actionButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];

    // copy the tag to more permanent storage
    memcpy( epc, self.tag.epc.bytes, 12 );

    [super viewWillAppear:animated];
}


- (void) viewWillDisappear:(BOOL)animated {
    
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


- (IBAction)toggleLocating {
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
    //self.locating = YES;

    // stop any old timer
    /*if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }*/

    NSLog( @"starting trace stream" );

    dispatch_async( self.dispatchQueue, ^{
        struct NUR_TRACETAG_DATA response;

        // request continuous tracing
        BYTE flags = NUR_TRACETAG_NO_EPC | NUR_TRACETAG_START_CONTINUOUS;
        int error = NurApiTraceTagByEPC( [Bluetooth sharedInstance].nurapiHandle, epc, 12, flags, &response );

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

        // call our trace method periodically
    //self.timer = [NSTimer scheduledTimerWithTimeInterval:TRACE_INTERVAL target:self selector:@selector(doTracePass) userInfo:nil repeats:YES];
    } );
}


- (void) stopLocating {
    //self.locating = NO;

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
    } );
}



//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_TRACETAG: {
            NSLog( @"trace" );
        }
    }
}

/*- (void) doTracePass {
    if ( ! self.locating ) {
        // nothing more to do, we've stopped
        NSLog( @"locate stopped, not doing trace pass");
        return;
    }

    NSLog( @"doing trace pass" );
}*/

@end
