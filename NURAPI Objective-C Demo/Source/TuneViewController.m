
#import <NurAPIBluetooth/Bluetooth.h>

#import "TuneViewController.h"
#import "AudioPlayer.h"
#import "UIButton+BackgroundColor.h"

@interface TuneViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation TuneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = @"Tune";

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
        // prompt the user to connect a reader
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                        message:@"No RFID reader connected!"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:@"Ok"
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                              // nothing special to do right now
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // show a status popup that has no ok/cancel buttons, it's shown as long as the saving takes
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Tuning"
                                                                    message:@"Tuning all enabled antennas."
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_ANTENNA_MAPPING antennaMap[NUR_MAX_ANTENNAS_EX];
        int antennaMappingCount;

        // get antenna mask
        int antennaError = NurApiGetAntennaMap( [Bluetooth sharedInstance].nurapiHandle, antennaMap, &antennaMappingCount, NUR_MAX_ANTENNAS_EX, sizeof(struct NUR_ANTENNA_MAPPING) );

        struct NUR_MODULESETUP setup;
        int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_ANTMASKEX, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            NSLog( @"failed to get module setup, error: %d", error );
        }

        NSLog( @"retrieved %d antenna mappings", antennaMappingCount );

        for ( unsigned int index = 0; index < 32; ++index ) {
            NSLog( @"checking for antenna %d", index );
            if ( setup.antennaMaskEx & (1<<index) ) {
                NSLog( @"tuning antenna %d", index );

                // play a short beep
                [[AudioPlayer sharedInstance] playSound:kBlep100ms];

                int error = NUR_NO_ERROR;
                int dbmResults[6] = { 0, 0, 0, 0, 0, 0 };

                // set up a message with the antenna name to show in the alert
                NSString * antennaName;
                if ( antennaError == NUR_NO_ERROR ) {
                    antennaName = [NSString stringWithFormat:@"Tuning antenna %@...",[NSString stringWithCString:antennaMap[ index ].name encoding:NSASCIIStringEncoding]];
                }
                else {
                    antennaName = [NSString stringWithFormat:@"Tuning antenna %d...", index];
                }

                // update the title
                dispatch_async( dispatch_get_main_queue(), ^{
                    alert.message = antennaName;
                });

                // tune this antenna
                if ( ( error = NurApiTuneAntenna( [Bluetooth sharedInstance].nurapiHandle, index, 1, 1, dbmResults)) != NUR_NO_ERROR ) {
                    NSLog( @"error %d tuning antenna %d", error, index );

                    // show error on UI thread
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        [self showErrorMessage:error];
                    });

                    return;
                }

                for ( int index = 0; index < 6; ++index ) {
                    NSLog( @"tuning result %d = %d", index, dbmResults[index] );
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        } );
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
