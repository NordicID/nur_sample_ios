
#import <CommonCrypto/CommonDigest.h>
#import <NurAPIBluetooth/Bluetooth.h>
#import <NurAPIBluetooth/NurAccessoryExtension.h>

#import "PerformUpdateViewController.h"
#import "Log.h"

@interface PerformUpdateViewController ()

@property (nonatomic, strong) UIAlertController * inProgressAlert;
@property (nonatomic, strong) NSData * firmwareData;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) DFUServiceController * dfuController;

@property (nonatomic, strong) NSString * dfuDeviceName;
@property (nonatomic, assign) BOOL shouldDoDummyConnect;

@end

@implementation PerformUpdateViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // the name of the device when it's in DFU mode
    self.dfuDeviceName = @"DfuExa";

    // we're not DFU flashing yet
    self.shouldDoDummyConnect = NO;

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewWillAppear:(BOOL)animated {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.firmwareTypeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Type: %@", @"Perform update view"), [Firmware getTypeString:self.firmware.type]];
    self.nameLabel.text         = [NSString stringWithFormat:NSLocalizedString(@"Name: %@", @"Perform update view"), self.firmware.name];
    self.versionLabel.text      = [NSString stringWithFormat:NSLocalizedString(@"Version: %@", @"Perform update view"), self.firmware.version];
    self.buildTimeLabel.text    = [NSString stringWithFormat:NSLocalizedString(@"Build time: %@", @"Perform update view"), [dateFormatter stringFromDate:self.firmware.buildTime]];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

    // when the view appears disable the idle timer so that the screen doesn't go to sleep
    // and interrupt the update
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // no longer updating, so re-enable the idle timer so that the screen can again blank
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


//*****************************************************************************************************************
#pragma mark - Download update

- (IBAction)downloadFirmware:(UIButton *)sender {
    logDebug( @"updating to firmware %@", self.firmware.name );

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
                                                      logError( @"failed to download firmware index file");
                                                      [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data!", nil)];
                                                      return;
                                                  }

                                                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                  if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                      if ( httpResponse ) {
                                                          logError( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          [self showErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                      }
                                                      else {
                                                          logError( @"failed to download firmware index file, no response" );
                                                          [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data, no response received!", nil)];
                                                      }

                                                      return;
                                                  }

                                                  logDebug( @"downloaded firmware, size: %lu bytes", (unsigned long)data.length);

                                                  // calculate the MD5 sum
                                                  NSString * md5Sum = [self md5:data];
                                                  if ( [self.firmware.md5 caseInsensitiveCompare:md5Sum] != NSOrderedSame ) {
                                                      logError( @"md5 sum mismatch, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                      [self showErrorMessage:NSLocalizedString(@"Checksum mismatch on downloaded firmware!", nil)];
                                                      return;
                                                  }

                                                  self.firmwareData = data;
                                                  
                                                  logDebug( @"md5 sum ok, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                  [self askForConfirmation];
                                              }];
        
        // start the download
        [downloadTask resume];
    }];
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


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first and wait for it to be completely dismissed before showing the error
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:^{
                self.inProgressAlert = nil;
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
            }];
        }
    } );
}


- (void) showNurApiErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    [self showErrorMessage:message];
}


//*****************************************************************************************************************
#pragma mark - Perform update

- (void) performUpdate {
    // hide the button so that more updates can not be triggered
    self.updateButton.hidden = YES;

    if ( self.firmware.type == kDeviceFirmware || self.firmware.type == kDeviceBootloader ) {
        [self performDeviceUpdate];
    }
    else {
        [self performNurUpdate];
    }
}


//*****************************************************************************************************************
#pragma mark - Device update

- (void) performDeviceUpdate {
    //    logDebug( @"performing a device update" );

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Updating device firmware", nil)
                                                               message:NSLocalizedString(@"Initializing...", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start updating
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        // perform the rebooting using a custom raw command
        dispatch_async(self.dispatchQueue, ^{
            // when we later find the device we do a dummy connect to it once
            self.shouldDoDummyConnect = YES;

            logDebug( @"DFU starting, putting the reader into DFU mode" );

            // send a custom raw command to the reader instructing it to restart in DFU mode
            BYTE command[2] = { ACC_EXT_RESTART, RESET_BOOTLOADER_DFU_START };
            int error = [[Bluetooth sharedInstance] writeRawCommand:NUR_CMD_ACC_EXT buffer:command bufferLen:2];

            if ( error != NUR_NO_ERROR ) {
                logError( @"failed to reboot reader into DFU mode");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showNurApiErrorMessage:error];
                    return;
                });
            }

            logDebug( @"reader rebooted ok, disconnecting and starting a scan to find the device after it is back in DFU mode" );
            [[Bluetooth sharedInstance] disconnectFromReader];
            [[Bluetooth sharedInstance] startDfuScanning];
        });
     }];
}


//*****************************************************************************************************************
#pragma mark - DFU delegate methods

- (void) dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond {
    logDebug( @"DFU progress, part: %ld, total: %ld, progress: %ld %%", (long)part, (long)totalParts, (long)progress );

    // update the alert
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            self.inProgressAlert.message = [NSString stringWithFormat:NSLocalizedString(@"Update progress %d%%", nil), progress];
        }
    });
}


- (void) logWith:(enum LogLevel)level message:(NSString *)message {
    logDebug( @"DFU log: %@", message );
}


- (void) dfuStateDidChangeTo:(enum DFUState)state {
    NSString * message = nil;

    switch ( state ) {
        case DFUStateConnecting:
            message = @"Connecting to the reader";
            break;
        case DFUStateStarting:
            message = @"Starting the update...";
            break;
        case DFUStateEnablingDfuMode:
            message = @"Enabling DFU mode...";
            break;
        case DFUStateUploading:
            message = @"Uploading the firmware to the reader...";
            break;
        case DFUStateValidating:
            message = @"Validating the update...";
            break;
        case DFUStateDisconnecting:
            message = @"Disconnecting from the reader";
            break;
        case DFUStateCompleted:
            message = @"The update completed successfully";
            break;
        case DFUStateAborted:
            message = @"The update was aborted!";
            break;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // special handling of the completed states
        if ( state == DFUStateCompleted || state == DFUStateAborted ) {
            logDebug( @"update completed, cleaning up" );

            // first restore the delegate from the central manager to the bluetooth manager
            // TODO: this should be moved into NurAPIBluetooth
            [Bluetooth sharedInstance].central.delegate = [Bluetooth sharedInstance];

            // dismiss the current progress alert
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:^{
                self.inProgressAlert = nil;

                // show a final alert with the finishing status
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Update finished", nil)
                                                                                message:message
                                                                         preferredStyle:UIAlertControllerStyleAlert];

                // when "Ok" is tapped pop off this view controller
                UIAlertAction* okButton = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Close", nil)
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               if ( self.navigationController ) {
                                                   [self.navigationController popToRootViewControllerAnimated:YES];
                                               }
                                               else if ( self.parentViewController && self.parentViewController.navigationController ) {
                                                   [self.parentViewController.navigationController popToRootViewControllerAnimated:YES];
                                               }
                                           }];


                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }];
        }

        // update the alert
        if ( message != nil ) {
            if ( self.inProgressAlert ) {
                self.inProgressAlert.message = message;
            }
        }
    });
}


- (void) dfuError:(enum DFUError)error didOccurWithMessage:(NSString *)message {
    logError( @"DFU error: %ld, message: %@", (long)error, message );

    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss the current progress alert
        [self.inProgressAlert dismissViewControllerAnimated:YES completion:^{
            self.inProgressAlert = nil;

            // show a final alert with the finishing status
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Update failed", nil)
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];

            // when "Ok" is tapped pop off this view controller
            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Close", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           if ( self.navigationController ) {
                                               [self.navigationController popToRootViewControllerAnimated:YES];
                                           }
                                           else if ( self.parentViewController && self.parentViewController.navigationController ) {
                                               [self.parentViewController.navigationController popToRootViewControllerAnimated:YES];
                                           }
                                       }];


            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }];
    });
}


//*****************************************************************************************************************
#pragma mark - NUR update

- (void) performNurUpdate {
    logDebug( @"performing a NUR update" );

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Updating NUR firmware", nil)
                                                               message:NSLocalizedString(@"Initializing...", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start updating
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        dispatch_async(self.dispatchQueue, ^{
            int error;

            // first enter bootloader mode
            if ( ! [self setBootloaderMode:'B'] ) {
                // failed to enter bootloader mode
                return;
            }

            // somewhat ugly casts...
            BYTE * buffer = (BYTE *)self.firmwareData.bytes;
            unsigned int bufferLength = (unsigned int)self.firmwareData.length;
            logDebug( @"now in bootloader mode, starting update, %d bytes", bufferLength );

            if ( self.firmware.type == kNurFirmware ) {
                error = NurApiProgramApp( [Bluetooth sharedInstance].nurapiHandle, buffer, bufferLength );
            }
            else if ( self.firmware.type == kNurBootloader ) {
                error = NurApiProgramBootloader( [Bluetooth sharedInstance].nurapiHandle, buffer, bufferLength );
            }
            else {
                // should not even be here...
                logError( @"can not update firmware of type: %@", self.firmware.name );
                return;
            }

            if ( error != NUR_NO_ERROR ) {
                // failed to start update
                logError( @"failed to start update, error: %d", error );
                [self showNurApiErrorMessage:error];

                // TODO: set back bootloader mode to application 'A'
                [self setBootloaderMode:'A'];
            }
            else {
                logDebug( @"update started ok" );
            }
        });
    }];
}


- (BOOL) setBootloaderMode:(char)newMode {
    int error;
    char currentMode;

    // first get the current mode, we may not need to switch modes if the current is already 'B'
    if ( (error = NurApiGetMode([Bluetooth sharedInstance].nurapiHandle, &currentMode )) != NUR_NO_ERROR ) {
        // failed to get mode
        [self showNurApiErrorMessage:error];
        return NO;
    }


    // enter the firmware update mode if we're still in application mode ('A')
    if ( currentMode == newMode) {
        // current mode is the one we want
        return YES;
    }

    logDebug( @"current mode '%c', entering mode '%c'", currentMode, newMode );
    if ( (error = NurApiEnterBoot([Bluetooth sharedInstance].nurapiHandle)) != NUR_NO_ERROR ) {
        // failed to enter bootloader mode
        [self showNurApiErrorMessage:error];
        return NO;
    }

    // now wait until the device is in bootloader mode and ready to be updated
    int loops = 0;
    while ( currentMode != newMode ) {
        if ( (error = NurApiGetMode([Bluetooth sharedInstance].nurapiHandle, &currentMode )) != NUR_NO_ERROR ) {
            // failed to get mode
            [self showNurApiErrorMessage:error];
            return NO;
        }

        logDebug( @"current mode: %c (%d)", currentMode, currentMode );

        // wait a bit for the device to boot into bootloader mode
        [NSThread sleepForTimeInterval:1.0f];
        loops++;

        // don't wait too long
        if ( loops == 60 ) {
            [self showErrorMessage:@"Reader failed to enter update mode"];
            return NO;
        }
    }

    return YES;
}


//*****************************************************************************************************************
#pragma mark - NUR flashing status

- (void) showFlashingFailed:(int)error {
    logError( @"flashing failed" );
    [self showNurApiErrorMessage:error];

    int error2;

    // enter the firmware update mode
    if ( (error2 = NurApiEnterBoot([Bluetooth sharedInstance].nurapiHandle)) != NUR_NO_ERROR ) {
        // failed to enter application mode
        return;
    }
}


- (void) showFlashingProgress:(int)current ofTotal:(int)total {
    if ( current == -1 ) {
        logDebug( @"first update, no progress yet" );
        return;
    }
    if ( total == 0 ) {
        logDebug( @"0 total pages, can not show progress!" );
        return;
    }

    int progressPercent = (int)((float)current / (float)total * 100);
    logDebug( @"current: %d, total: %d, progress: %d%%", current, total, progressPercent );

    // update the alert
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            self.inProgressAlert.message = [NSString stringWithFormat:NSLocalizedString(@"Update progress %d%%", nil), progressPercent];
        }
    });
}


- (void) showFlashingCompleted {
    logDebug( @"flashing completed" );

    // enter application mode again
    int error;
    if ( (error = NurApiEnterBoot([Bluetooth sharedInstance].nurapiHandle)) != NUR_NO_ERROR ) {
        // failed to enter bootloader mode
        [self showNurApiErrorMessage:error];
        return;
    }

    // update the alert
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            self.inProgressAlert.message = NSLocalizedString(@"Rebooting device", nil);
        }
    });

    char mode = '?';

    // now wait until the device is in application mode again
    int loops = 0;
    while ( mode != 'A' ) {
        if ( (error = NurApiGetMode([Bluetooth sharedInstance].nurapiHandle, &mode )) != NUR_NO_ERROR ) {
            // failed to get mode
            [self showNurApiErrorMessage:error];
            return;
        }

        logDebug( @"mode: %c (%d)", mode, mode );

        // wait a bit for the device to boot into bootloader mode
        [NSThread sleepForTimeInterval:1.0f];
        loops++;

        // don't wait too long
        if ( loops == 60 ) {
            [self showErrorMessage:@"Reader failed to enter application mode"];
            return;
        }
    }

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

- (void) readerInDfuModeFound:(CBPeripheral *)reader {
    logDebug( @"found reader %@ in DFU mode", reader.identifier.UUIDString);

    // should we not do the initial reconnect to the device and scan services?
    if ( self.shouldDoDummyConnect ) {
        logDebug(@"doing a dummy connect to device in DFU mode" );
        self.shouldDoDummyConnect = NO;
        if ( ![[Bluetooth sharedInstance] connectToReader:reader] ) {
            // failed to reconnect...
            logError(@"failed to do dummy connect to the device" );
        }

        // after 10s do the disconnect
        logDebug(@"waiting 10s and then disconnecting and doing a new DFU scan" );
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), self.dispatchQueue, ^{
            logDebug( @"delay elapsed, disconnecting" );
            [[Bluetooth sharedInstance] disconnectFromReader];
        });

        return;
    }

    // is it one of ours?
//    if ( [self.dfuDeviceName caseInsensitiveCompare:reader.name] != NSOrderedSame ) {
//        logDebug( @"device %@ is not an EXA device (%@), ignoring", reader.name, self.dfuDeviceName );
//        return;
//    }

    // stop scanning for new devices, one is enough
    [[Bluetooth sharedInstance] stopScanning];

    logDebug(@"waiting 3s and then starting the real DFU update" );
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), self.dispatchQueue, ^{
        DFUFirmwareType type = self.firmware.type == kDeviceFirmware ? DFUFirmwareTypeApplication : DFUFirmwareTypeBootloader;
        //DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithZipFile:self.firmwareData type:type];

        // set up the DFU initiator.
        // NOTE: this will take over the delegate from us!
        DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithCentralManager:[Bluetooth sharedInstance].central
                                                                                      target:reader];
        //[initiator withFirmware:selectedFirmware];

        initiator.logger = self; // - to get log info
        initiator.delegate = self; // - to be informed about current state and errors
        initiator.progressDelegate = self;
        initiator.packetReceiptNotificationParameter = 12;
        initiator.forceDfu = NO;
        // initiator.peripheralSelector = ... // the default selector is used

        self.dfuController = [initiator start];
        logDebug( @"DFU has started" );
    });
}


- (void) readerDisconnected {
    logDebug( @"reader disconnected" );
    if ( !self.shouldDoDummyConnect ) {
        logDebug( @"dummy reconnect done, starting a new scan for DFU devices for the real update" );
        [[Bluetooth sharedInstance] startDfuScanning];
    }
}


- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_PRGPRGRESS: {
            const struct NUR_PRGPROGRESS_DATA *progress = (const struct NUR_PRGPROGRESS_DATA *)data;
            logDebug( @"error code: %d", progress->error );
            logDebug( @"current page: %d", progress->curPage );
            logDebug( @"total pagse: %d", progress->totalPages );

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
