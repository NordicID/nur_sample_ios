
#import <CommonCrypto/CommonDigest.h>
#import <NurAPIBluetooth/Bluetooth.h>

#import "PerformUpdateViewController.h"

@interface PerformUpdateViewController ()

@property (nonatomic, strong) UIAlertController * inProgressAlert;
@property (nonatomic, strong) NSData * firmwareData;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation PerformUpdateViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewWillAppear:(BOOL)animated {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version: %@", nil), self.firmware.version];
    self.buildTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Build time: %@", nil), [dateFormatter stringFromDate:self.firmware.buildTime]];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}


- (IBAction)downloadFirmware:(UIButton *)sender {
    NSLog( @"updating to firmware %@", self.firmware.name );

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Downloading firmware", nil)
                                                               message:NSLocalizedString(@"Downloading firmware data, please wait.", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start downloading
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        // create a download task for downloading the index file
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                              dataTaskWithURL:self.firmware.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                  if ( error != nil ) {
                                                      NSLog( @"failed to download firmware index file");
                                                      [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data!", nil)];
                                                      return;
                                                  }

                                                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                  if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                      if ( httpResponse ) {
                                                          NSLog( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          [self showErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                      }
                                                      else {
                                                          NSLog( @"failed to download firmware index file, no response" );
                                                          [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data, no response received!", nil)];
                                                      }

                                                      return;
                                                  }

                                                  NSLog( @"downloaded firmware, size: %lu bytes", (unsigned long)data.length);

                                                  // calculate the MD5 sum
                                                  NSString * md5Sum = [self md5:data];
                                                  if ( [self.firmware.md5 caseInsensitiveCompare:md5Sum] != NSOrderedSame ) {
                                                      NSLog( @"md5 sum mismatch, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                      [self showErrorMessage:NSLocalizedString(@"Checksum mismatch on downloaded firmware!", nil)];
                                                      return;
                                                  }

                                                  self.firmwareData = data;
                                                  
                                                  NSLog( @"md5 sum ok, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                  [self askForConfirmation];
                                              }];
        
        // start the download
        [downloadTask resume];
    }];
}


- (void) askForConfirmation {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:^{
                self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", nil)
                                                                           message:NSLocalizedString(@"Proceed with updating the firmware?", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* proceedButton = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Proceed", nil)
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    // user confirmed, proceed!
                                                    [self performUpdate];
                                                }];

                UIAlertAction* cancelButton = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                style:UIAlertActionStyleCancel
                                                handler:nil];

                [self.inProgressAlert addAction:proceedButton];
                [self.inProgressAlert addAction:cancelButton];

                // when the dialog is up, then start downloading
                [self presentViewController:self.inProgressAlert animated:YES completion:nil];
            }];
        }
    });
}


- (void) performUpdate {
    NSLog( @"performing update" );

    // hide the button so that more updates can not be triggered
    self.updateButton.hidden = YES;

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Updating firmware", nil)
                                                               message:NSLocalizedString(@"Update progress 0%", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start updating
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        dispatch_async(self.dispatchQueue, ^{
            // somewhat ugly casts...
            BYTE * buffer = (BYTE *)self.firmwareData.bytes;
            unsigned int bufferLength = (unsigned int)self.firmwareData.length;
            NSLog( @"starting update, %d bytes", bufferLength );
            int error = NurApiProgramApp( [Bluetooth sharedInstance].nurapiHandle, buffer, bufferLength );
            if ( error != NUR_NO_ERROR ) {
                // failed to start update
                NSLog( @"failed to start update, error: %d", error );
                [self showNurApiErrorMessage:error];
            }
        });
    }];
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            self.inProgressAlert = nil;
        }

        // show in an alert view
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // nothing special to do right now
                                   }];


        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    } );
}


- (void) showNurApiErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    [self showErrorMessage:message];
}


- (NSString *) md5:(NSData *)input {
    // perform the MD5 digest
    unsigned char digest[16];
    CC_MD5( input.bytes, (unsigned int)input.length, digest );

    // convert to a hex string
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}


//*****************************************************************************************************************
#pragma mark - Flashing status

- (void) showFlashingFailed:(int)error {
    NSLog( @"flashing failed" );
    [self showNurApiErrorMessage:error];
}


- (void) showFlashingProgress:(int)current ofTotal:(int)total {
    if ( current == -1 ) {
        NSLog( @"first update, no progress yet" );
        return;
    }
    if ( total == 0 ) {
        NSLog( @"0 total pages, can not show progress!" );
        return;
    }

    int progressPercent = (int)((float)current / (float)total * 100);
    NSLog( @"current: %d, total: %d, progress: %d%%", current, total, progressPercent );

    // update the alert
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            self.inProgressAlert.message = [NSString stringWithFormat:NSLocalizedString(@"Update progress %d%", nil), progressPercent];
        }
    });
}


- (void) showFlashingCompleted {
    NSLog( @"flashing completed" );

    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            self.inProgressAlert = nil;
        }

        // show in an alert view
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Update completed", nil)
                                                                        message:@"The firmware update completed successfully"
                                                                 preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // nothing special to do right now
                                   }];


        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    } );

}


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_PRGPRGRESS: {
            const struct NUR_PRGPROGRESS_DATA *progress = (const struct NUR_PRGPROGRESS_DATA *)data;
            NSLog( @"error code: %d", progress->error );
            NSLog( @"current page: %d", progress->curPage );
            NSLog( @"total pagse: %d", progress->totalPages );

            // failed?
            if ( progress->error != NUR_NO_ERROR ) {
                [self showFlashingFailed:progress->error];
                return;
            }

            // progress?
            if ( progress->curPage < progress->totalPages ) {
                [self showFlashingProgress:progress->curPage ofTotal:progress->totalPages];
                return;
            }

            // completed?
            if ( progress->curPage == progress->totalPages ) {
                [self showFlashingCompleted];
            }
        }
    }
}

@end
