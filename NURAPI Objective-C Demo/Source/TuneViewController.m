
#import <NurAPIBluetooth/Bluetooth.h>

#import "TuneViewController.h"
#import "AudioPlayer.h"
#import "UIViewController+ErrorMessage.h"

@interface TuneViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation TuneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}



- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // register for bluetooth events
    //[[Bluetooth sharedInstance] registerDelegate:self];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Tune", nil);
}


/*- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}*/


- (IBAction)tune:(UIButton *)sender {
    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        // prompt the user to connect a reader
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:NSLocalizedString(@"No RFID reader connected!", nil)
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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tuning", nil)
                                                                    message:NSLocalizedString(@"Tuning all enabled antennas.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];

    // clear the result text
    self.resultText.text = @"";

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_ANTENNA_MAPPING antennaMap[NUR_MAX_ANTENNAS_EX];
        int antennaMappingCount;

        // get antenna mask
        int antennaError = NurApiGetAntennaMap( [Bluetooth sharedInstance].nurapiHandle, antennaMap, &antennaMappingCount, NUR_MAX_ANTENNAS_EX, sizeof(struct NUR_ANTENNA_MAPPING) );

        struct NUR_MODULESETUP setup;
        int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_ANTMASKEX, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            logError( @"failed to get module setup, error: %d", error );
        }

        logDebug( @"retrieved %d antenna mappings", antennaMappingCount );

        for ( unsigned int index = 0; index < 32; ++index ) {
            logDebug( @"checking for antenna %d", index );
            if ( setup.antennaMaskEx & (1<<index) ) {
                logDebug( @"tuning antenna %d", index );

                // play a short beep
                [[AudioPlayer sharedInstance] playSound:kBlep100ms];

                int error = NUR_NO_ERROR;
                int dbmResults[6] = { 0, 0, 0, 0, 0, 0 };

                // set up a message with the antenna name to show in the alert
                NSString * antennaName;
                if ( antennaError == NUR_NO_ERROR ) {
                    antennaName = [NSString stringWithFormat:NSLocalizedString(@"Tuning antenna %@...", nil), [NSString stringWithCString:antennaMap[ index ].name encoding:NSASCIIStringEncoding]];
                }
                else {
                    antennaName = [NSString stringWithFormat:NSLocalizedString(@"Tuning antenna %d...", nil), index];
                }

                // update the title
                dispatch_async( dispatch_get_main_queue(), ^{
                    alert.message = antennaName;
                });

                BOOL wideTune = 1;
                BOOL saveResults = 1;

                // tune this antenna
                if ( ( error = NurApiTuneAntenna( [Bluetooth sharedInstance].nurapiHandle, index, wideTune, saveResults, dbmResults)) != NUR_NO_ERROR ) {
                    logError( @"error %d tuning antenna %d", error, index );

                    // show error on UI thread
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        [self showNurApiErrorMessage:error];
                    });

                    return;
                }

                // show the result to the user
                NSString * result = antennaName;
                for ( int index = 0; index < 6; ++index ) {
                    float dBm = dbmResults[index] / 1000.0f;
                    logDebug( @"tuning result %d = %.1f dBm", index, dBm );
                    result = [result stringByAppendingFormat:@"\n    %d = %.1f", index, dBm];
                }

                dispatch_async( dispatch_get_main_queue(), ^{
                    self.resultText.text = [self.resultText.text stringByAppendingFormat:@"%@\n\n", result];
                });
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        } );
    });
}


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_TUNEEVENT: {
            const struct NUR_TUNEEVENT_DATA *tuneData = (const struct NUR_TUNEEVENT_DATA *)data;
            logDebug( @"tuning antenna %d, frequency: %d, reflected power value: %d", tuneData->antenna, tuneData->freqKhz, tuneData->reflPower_dBm );
        }
    }
}

@end
