
#import <NurAPIBluetooth/Bluetooth.h>

#import "ReaderSettingsViewController.h"
#import "ConnectionManager.h"
#import "Firmware.h"
#import "UIViewController+ErrorMessage.h"


@interface ReaderSettingsViewController () {
    BOOL settingsRead;
    BOOL writeInProgress;
    NUR_ACC_CONFIG config;
    int wirelessStatus;
    enum PAIRING_MODE allowPairing;
    BOOL allowPairingAvailable;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSString * restoreUuid;

@end


@implementation ReaderSettingsViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // no settings read yet
    settingsRead = NO;
    writeInProgress = NO;
    wirelessStatus = 0;
    allowPairingAvailable = NO;
    self.restoreUuid = nil;

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &self->config, sizeof(NUR_ACC_CONFIG) );
        if (error != NUR_NO_ERROR) {
            [self showNurApiErrorMessage:error];
            return;
        }

        // NOTE: this returns a NUR_ERROR_HW_MISMATCH when the device does not support wireless charging, even though the device
        // responded ok and there was no communication error. So ignore that error here.
        error = NurAccGetWirelessChargeStatus( [Bluetooth sharedInstance].nurapiHandle, &self->wirelessStatus);
        if (error != NUR_NO_ERROR && error != NUR_ERROR_HW_MISMATCH) {
            self->wirelessStatus = WIRELESS_CHARGE_NOT_SUPPORTED;
        }

        TCHAR deviceVersionsTmp[32] = _T("");
        NSString * deviceVersions;

        // fetch device firmware version to see if the "allow pairing" should be available. If the firmware version is > 2.2.1 then
        // the setting is available, else not
        error = NurAccGetFwVersion( [Bluetooth sharedInstance].nurapiHandle, deviceVersionsTmp, 32);
        if (error != NUR_NO_ERROR) {
            [self showNurApiErrorMessage:error];
            return;
        }

        deviceVersions = [NSString stringWithCString:deviceVersionsTmp encoding:NSASCIIStringEncoding];

        NSArray * parts = [deviceVersions componentsSeparatedByString:@";"];
        if ( parts.count != 2 ) {
            logError( @"unexpected device firmware version format: '%@'", deviceVersions);
            [self showErrorMessage:@"Unexpected device firmware version format"];
        }
        else {
            // get the current pairing mode. If the device does not support pairing this call
            // is assumed to fail
            int mode;
            error = NurAccGetPairingMode( [Bluetooth sharedInstance].nurapiHandle, &mode);
            if (error != NUR_NO_ERROR) {
                self->allowPairingAvailable = NO;
            }
            else {
                self->allowPairingAvailable = YES;
                self->allowPairing = mode == PAIRING_ENABLE ? PAIRING_ENABLE : PAIRING_DISABLE;
            }
        }

        self->settingsRead = YES;

        // now we can show the data
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Reader Settings", nil);

    [[ConnectionManager sharedInstance] registerDelegate:self];
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[ConnectionManager sharedInstance] deregisterDelegate:self];
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ( ! settingsRead ) {
        return 0;
    }

    if ( [ConnectionManager sharedInstance].deviceSupportsBarcodes ) {
        return 3;
    }
    else {
        return 2;
    }
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"HID Modes", @"Reader settings section title");
        case 1:
            return NSLocalizedString(@"Connection", @"Reader settings section title");
        default:
            return NSLocalizedString(@"Wireless Charging", @"Reader settings section title");
    }
}


- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return nil;

        case 1:
            if ( !allowPairingAvailable ) {
                return NSLocalizedString(@"Pairing setting is not available with this firmware version", @"Reader settings pairing section footer");
            }
            else {
                return nil;
            }

        default:
            // in case there is an error
            switch ( wirelessStatus ) {
                case WIRELESS_CHARGE_REFUSED:
                case WIRELESS_CHARGE_FAIL:
                case WIRELESS_CHARGE_NOT_SUPPORTED:
                    return NSLocalizedString(@"Wireless charging is not available", @"Reader settings wireless section footer");

                default:
                    return nil;
            }
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! settingsRead ) {
        return 0;
    }

    switch ( section ) {
        case 0:
            if ( [ConnectionManager sharedInstance].deviceSupportsBarcodes ) {
                return 2;
            }
            else {
                return 1;
            }
        case 1:
            return 1;
        default:
            return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReaderSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReaderSettingCell" forIndexPath:indexPath];
    cell.delegate = self;

    switch ( indexPath.section ) {
        case 0:
            switch ( indexPath.row ) {
                case kHidRfidEnabled:
                    cell.titleLabel.text = NSLocalizedString(@"HID RFID", nil);
                    cell.settingEnabled = config.flags & NUR_ACC_FL_HID_RFID ? YES : NO;
                    cell.settingType = kHidRfidEnabled;
                    break;

                case kHidBarcodeEnabled:
                    cell.titleLabel.text = NSLocalizedString(@"HID barcode", nil);
                    cell.settingEnabled = config.flags & NUR_ACC_FL_HID_BARCODE ? YES : NO;
                    cell.settingType = kHidBarcodeEnabled;
                    break;
           }
            break;

        case 1:
            cell.titleLabel.text = NSLocalizedString(@"Allow pairing", nil);
            cell.settingType = kAllowPairing;

            if ( allowPairingAvailable ) {
                // pairing can be changed
                cell.settingEnabled = allowPairing;
                cell.enabledSwitch.enabled = YES;
                cell.enabledSwitch.hidden = NO;
            }
            else {
                // can't change pairing
                cell.settingEnabled = NO;
                cell.enabledSwitch.enabled = NO;
                cell.enabledSwitch.hidden = YES;
            }
            break;

        default:
            cell.enabledSwitch.enabled = YES;
            cell.enabledSwitch.hidden = NO;

            // wireless charging
            switch ( indexPath.row + kWirelessChargingEnabled) {
                case kWirelessChargingEnabled:
                    cell.titleLabel.text = NSLocalizedString(@"Wireless charging", nil);
                    cell.settingType = kWirelessChargingEnabled;

                    switch ( wirelessStatus ) {
                        case WIRELESS_CHARGE_OFF:
                            cell.settingEnabled = NO;
                            break;

                        case WIRELESS_CHARGE_ON:
                            cell.settingEnabled = YES;
                            break;

                        case WIRELESS_CHARGE_REFUSED:
                        case WIRELESS_CHARGE_FAIL:
                        case WIRELESS_CHARGE_NOT_SUPPORTED:
                            cell.titleLabel.text = NSLocalizedString(@"Wireless charging is not available", nil);
                            cell.settingEnabled = NO;

                            // no switch if we can't switch anything
                            cell.enabledSwitch.enabled = NO;
                            cell.enabledSwitch.hidden = YES;
                    }
                    break;

                default:
                    logError(@"unknown setting: %ld in section: %ld", (long)indexPath.row, (long)indexPath.section);
                    break;
            }
    }
    
    return cell;
}


//******************************************************************************************
#pragma mark - Reader Setting Delegate
- (void) setting:(ReaderSettingType)setting hasChanged:(BOOL)enabled {
    switch ( setting ) {
        case kHidBarcodeEnabled:
            config.flags ^= NUR_ACC_FL_HID_BARCODE;
            break;

        case kHidRfidEnabled:
            config.flags ^= NUR_ACC_FL_HID_RFID;
            break;

        case kWirelessChargingEnabled:
            wirelessStatus = enabled ? WIRELESS_CHARGE_ON : WIRELESS_CHARGE_OFF;
            break;

        case kAllowPairing: {
            // ask for confirmation
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", nil)
                                                                            message:NSLocalizedString(@"Changing the pairing setting will reboot the reader. Do you want to proceed?", nil)
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* proceedButton = [UIAlertAction
                                            actionWithTitle:NSLocalizedString(@"Proceed", nil)
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                // user confirmed, save settings and reboot afterwards
                self->allowPairing = enabled;
                [self saveSettings:YES];
            }];

            UIAlertAction* cancelButton = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction * action) {
                                               // reload the content to reset the switch
                                               [self.tableView reloadData];
                                           }];

            [alert addAction:proceedButton];
            [alert addAction:cancelButton];

            // when the dialog is up, then start downloading
            [self presentViewController:alert animated:YES completion:nil];
            logDebug( @"dialog done" );
            return;
        }
    }

    [self saveSettings:NO];
}


- (void) saveSettings:(BOOL)reboot {
    if ( writeInProgress ) {
        logDebug( @"write already in progress, skipping" );
        return;
    }

    writeInProgress = YES;

    dispatch_async(self.dispatchQueue, ^{
        // write current settings
        int error = NurAccSetConfig( [Bluetooth sharedInstance].nurapiHandle, &self->config, sizeof(NUR_ACC_CONFIG) );
        if (error != NUR_NO_ERROR) {
            // failed to fetch tag
            [self showNurApiErrorMessage:error];
        }

        if ( self->wirelessStatus == WIRELESS_CHARGE_ON ) {
            error = NurAccSetWirelessCharge( [Bluetooth sharedInstance].nurapiHandle, 1, &self->wirelessStatus );
        }
        else if ( self->wirelessStatus == WIRELESS_CHARGE_OFF ) {
            error = NurAccSetWirelessCharge( [Bluetooth sharedInstance].nurapiHandle, 0, &self->wirelessStatus );
        }
        else {
            // nothing for us
            self->writeInProgress = NO;
        }

        if (error != NUR_NO_ERROR) {
            // failed to fetch tag
            [self showNurApiErrorMessage:error];
            self->writeInProgress = NO;
            return;
        }

        // save the allow pairing setting
        if ( allowPairingAvailable ) {
            error = NurAccSetPairingMode( [Bluetooth sharedInstance].nurapiHandle, allowPairing ? PAIRING_ENABLE : PAIRING_DISABLE );
            if (error != NUR_NO_ERROR) {
                [self showNurApiErrorMessage:error];
            }
        }

        self->writeInProgress = NO;

        if ( reboot ) {
            // save the UUID of this current device so that we can after the reboot reconnect to it
            self.restoreUuid = [Bluetooth sharedInstance].currentReader.identifier.UUIDString;
            //[[Bluetooth sharedInstance] disconnectFromReader];

            logDebug(@"rebooting device");
            error = NurAccRestart( [Bluetooth sharedInstance].nurapiHandle );
            if (error != NUR_NO_ERROR) {
                [self showNurApiErrorMessage:error];
            }
        }
    });
}

//******************************************************************************************
#pragma mark - Connection Manager Delegate
- (void) readerDisconnected {
    logDebug( @"reader is now disconnected, restoring connection again to the same reader");
    [[ConnectionManager sharedInstance] deregisterDelegate:self];

    if ( self.restoreUuid ) {
        [[Bluetooth sharedInstance] restoreConnection:self.restoreUuid];
    }

    // get rid of this settings view
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.navigationController ) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else if ( self.parentViewController && self.parentViewController.navigationController ) {
            [self.parentViewController.navigationController popViewControllerAnimated:YES];
        }
    });
}


@end
