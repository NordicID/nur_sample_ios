
#import <NurAPIBluetooth/Bluetooth.h>

#import "TuneViewController.h"
#import "UIButton+BackgroundColor.h"

@interface TuneViewController ()

@end

@implementation TuneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
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
        int error = NUR_NO_ERROR;

        for ( unsigned int index = 0; index < 32; ++index ) {
            if ( self.antennaMask & (1<<index) ) {
                NSLog( @"tuning antenna %d", index );

                // tune this antenna
                int dbmResults[6];
                if ( ( error = NurApiTuneAntenna( [Bluetooth sharedInstance].nurapiHandle, index, 1, 1, dbmResults)) != NUR_NO_ERROR ) {
                    NSLog( @"error tuning antenna %d", index );
                    break;
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != NUR_NO_ERROR) {
                // failed to fetch tag
                [self showErrorMessage:error];
                return;
            }
            else {
                // tuned ok
                NSLog( @"tune ok" );
            }
        });
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


@end
