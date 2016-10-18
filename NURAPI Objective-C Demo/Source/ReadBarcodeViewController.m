
#import "ReadBarcodeViewController.h"

@interface ReadBarcodeViewController () {
    BOOL readingBarcode;
    BOOL ignoreTrigger;
}

@end

@implementation ReadBarcodeViewController

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


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    //NSLog( @"received notification: %d, data: %d bytes", type, length );

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
                    NurAccBeepAsync( [Bluetooth sharedInstance].nurapiHandle, 100 );
                }
                else if (status == NUR_ERROR_NOT_READY) {
                    NSLog( @"barcode reading cancelled" );
                    ignoreTrigger = YES;
                }
                else {
                    [self showErrorMessage:status];
                    NurAccBeepAsync( [Bluetooth sharedInstance].nurapiHandle, 500 );
                }

                [self showStatus:@"Press trigger to read barcode"];
            }
        }
            break;

        case NUR_NOTIFICATION_IOCHANGE: {
            struct NUR_IOCHANGE_DATA *iocData = (struct NUR_IOCHANGE_DATA *)data;
            if (iocData->source == NUR_ACC_TRIGGER_SOURCE) {
                NSLog( @"trigger changed, dir: %d", iocData->dir );
                if (iocData->dir == 0) {
                    if (!readingBarcode && !ignoreTrigger) {
                        NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_BLINK);
                        if (NurAccReadBarcodeAsync( [Bluetooth sharedInstance].nurapiHandle, 5000) == NUR_SUCCESS) {
                            readingBarcode = YES;
                            [self showStatus:@"Reading barcode..."];
                            [self showBarcode:@""];
                        }
                        else {
                            NurAccBeepAsync( [Bluetooth sharedInstance].nurapiHandle, 1000);
                            NurAccSetLedOpMode( [Bluetooth sharedInstance].nurapiHandle, NUR_ACC_LED_UNSET);
                        }
                    }

                    ignoreTrigger = NO;
                }
            }
        }
            break;
            
        default:
            break;
    }
}


@end