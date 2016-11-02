
#import <NurAPIBluetooth/Bluetooth.h>

#import "TuneViewController.h"
#import "UIButton+BackgroundColor.h"

@interface TuneViewController ()

@end

@implementation TuneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    //self.dispatchQueue = dispatch_queue_create("com.nordicid.rfiddemo.tune", 0);
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tuneButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
}


- (IBAction)tune:(UIButton *)sender {
    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        NSLog( @"no current reader connected, aborting tuning" );
        return;
    }

    dispatch_async(self.dispatchQueue, ^{
        for ( unsigned int index = 0; index < 32; ++index ) {
            NSLog( @"checking for antenna %d", index );
            if ( self.antennaMask & (1<<index) ) {
                NSLog( @"tuning antenna %d", index );

                int error = NUR_NO_ERROR;
                int dbmResults[6];

                // tune this antenna
                if ( ( error = NurApiTuneAntenna( [Bluetooth sharedInstance].nurapiHandle, index, 1, 1, dbmResults)) != NUR_NO_ERROR ) {
                    NSLog( @"error %d tuning antenna %d", error, index );

                    // show error on UI thread
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [self showErrorMessage:error];
                    });

                    return;
                }
            }
        }
        
        /*dispatch_async( dispatch_get_main_queue(), ^{
            if (error != NUR_NO_ERROR) {
                // failed to fetch tag
                [self showErrorMessage:error];
                return;
            }
            else {
                // tuned ok
                NSLog( @"tune ok" );
            }
        });*/
    });
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


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_TUNEEVENT: {
            NSLog( @"tuning..." );
        }
    }
}

@end
