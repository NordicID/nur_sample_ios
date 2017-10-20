
#import "ReadBarcodeViewController.h"
#import "AudioPlayer.h"

@interface ReadBarcodeViewController () {
    BOOL readingBarcode;
    BOOL ignoreTrigger;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation ReadBarcodeViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // if we have no reader show a different message
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self showStatus:NSLocalizedString(@"Please connect an RFID reader", nil)];
    }

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    readingBarcode = NO;
    ignoreTrigger = NO;

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}


- (void) showErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    NSLog( @"NURAPI error: %@", message );

    // show the error as a message
    [self showBarcode:message];
}


- (void) showStatus:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"status: %@, %@", status, self.status );
        self.status.text = status;
    } );
}


- (void) showBarcode:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.barcode.text = status;
        self.barcode.hidden = NO;
    } );
}


- (IBAction)scanBarcode:(id)sender {
    if (!readingBarcode && !ignoreTrigger) {
        dispatch_async(self.dispatchQueue, ^{

            NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_BLINK);
            if (NurAccReadBarcodeAsync( [Bluetooth sharedInstance].nurapiHandle, 5000) == NUR_SUCCESS) {
                readingBarcode = YES;
                [self showStatus:NSLocalizedString(@"Reading barcode...", nil)];
                [self showBarcode:@""];
            }
            else {
                NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_UNSET);
            }

            ignoreTrigger = NO;
        } );
    }
}


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    NSLog( @"received notification: %d, data: %d bytes", type, length );

    switch(type) {
        case NUR_NOTIFICATION_ACCESSORY: {
            BYTE *dataPtr = (BYTE*)data;
            BYTE evType = dataPtr[0];
            int status = NurApiGetLastNotificationStatus( [Bluetooth sharedInstance].nurapiHandle );
            if (evType == NUR_ACC_EVENT_BARCODE) {
                readingBarcode = NO;
                NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_UNSET);

                if (status == NUR_SUCCESS) {
                    NSString * barcode = [NSString stringWithCString:(char*)&dataPtr[1] encoding:NSUTF8StringEncoding];
                    NSLog( @"barcode: %@", barcode );
                    [self showBarcode:barcode];

                    // play a short blip
                    [[AudioPlayer sharedInstance] playSound:kBlep100ms];
                }
                else if (status == NUR_ERROR_NOT_READY) {
                    NSLog( @"barcode reading cancelled" );
                    ignoreTrigger = YES;
                }
                else if ( status == NUR_ERROR_NO_TAG ) {
                    [self showBarcode:NSLocalizedString(@"No barcode found", nil)];
                }
                else {
                    [self showErrorMessage:status];
                }

                [self showStatus:NSLocalizedString(@"Press trigger to read barcode", nil)];
            }
        }
            break;

        case NUR_NOTIFICATION_IOCHANGE: {
            struct NUR_IOCHANGE_DATA *iocData = (struct NUR_IOCHANGE_DATA *)data;
            switch (iocData->source ) {
                case NUR_ACC_TRIGGER_SOURCE:
                NSLog( @"trigger changed, dir: %d", iocData->dir );
                if (iocData->dir == 0) {
                    if (!readingBarcode && !ignoreTrigger) {
                        NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_BLINK);
                        if (NurAccReadBarcodeAsync( [Bluetooth sharedInstance].nurapiHandle, 5000) == NUR_SUCCESS) {
                            readingBarcode = YES;
                            [self showStatus:NSLocalizedString(@"Reading barcode...", nil)];
                            [self showBarcode:@""];
                        }
                        else {
                            NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_UNSET);
                        }
                    }

                    ignoreTrigger = NO;
                }
                    break;
                case 101:
                    NSLog( @"I/O change for source: %d (power or pairing button)", iocData->source );
                    break;

                case 102:
                    NSLog( @"I/O change for source: %d (power or pairing button)", iocData->source );
                    break;

                default:
                    NSLog( @"I/O change for unknown source: %d", iocData->source );
                    break;
            }
        }
            break;
            
        default:
            break;
    }
}


@end
