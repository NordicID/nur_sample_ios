
#import <NurAPIBluetooth/Bluetooth.h>

#import "ReaderSettingsViewController.h"
#import "ConnectionManager.h"


@interface ReaderSettingsViewController () {
    BOOL settingsRead;
    BOOL writeInProgress;
    NUR_ACC_CONFIG config;
    int wirelessStatus;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

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

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &config, sizeof(NUR_ACC_CONFIG) );
        if (error != NUR_NO_ERROR) {
            [self showErrorMessage:error];
            return;
        }

        error = NurAccGetWirelessChargeStatus( [Bluetooth sharedInstance].nurapiHandle, &wirelessStatus);
        if (error != NUR_NO_ERROR) {
            [self showErrorMessage:error];
            return;
        }

        settingsRead = YES;

        // now we can show the data
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Reader Settings", nil);
}


- (void) showErrorMessage:(int)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        // extract the NURAPI error
        char buffer[256];
        NurApiGetErrorMessage( error, buffer, 256 );
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

        NSLog( @"NURAPI error: %@", message );

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
    });
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ( ! settingsRead ) {
        return 0;
    }

    return 2;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"HID Modes", @"Reader settings section title");
        default:
            return NSLocalizedString(@"Wireless Charging", @"Reader settings section title");
    }
}


- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ( section == 0 ) {
        return nil;
    }

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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! settingsRead ) {
        return 0;
    }

    switch ( section ) {
        case 0:
            return 2;

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
                case kHidBarcodeEnabled:
                    cell.titleLabel.text = NSLocalizedString(@"HID barcode", nil);
                    cell.settingEnabled = config.flags & NUR_ACC_FL_HID_BARCODE ? YES : NO;
                    cell.settingType = kHidBarcodeEnabled;
                    break;

                case kHidRfidEnabled:
                    cell.titleLabel.text = NSLocalizedString(@"HID RFID", nil);
                    cell.settingEnabled = config.flags & NUR_ACC_FL_HID_RFID ? YES : NO;
                    cell.settingType = kHidRfidEnabled;
                    break;
            }
            break;

        default:
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
                            cell.enabledSwitch.enabled = NO;
                    }
                    break;

                default:
                    NSLog(@"unknown setting: %ld in section: %ld", (long)indexPath.row, (long)indexPath.section);
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
    }

    [self saveSettings];
}


- (void) saveSettings {
    if ( writeInProgress ) {
        NSLog( @"write already in progress, skipping" );
        return;
    }

    writeInProgress = YES;

    dispatch_async(self.dispatchQueue, ^{
        // write current settings
        int error = NurAccSetConfig( [Bluetooth sharedInstance].nurapiHandle, &config, sizeof(NUR_ACC_CONFIG) );
        if (error != NUR_NO_ERROR) {
            // failed to fetch tag
            [self showErrorMessage:error];
        }

        if ( wirelessStatus == WIRELESS_CHARGE_ON ) {
            error = NurAccSetWirelessCharge( [Bluetooth sharedInstance].nurapiHandle, 1, &wirelessStatus );
        }
        else if ( wirelessStatus == WIRELESS_CHARGE_OFF ) {
            error = NurAccSetWirelessCharge( [Bluetooth sharedInstance].nurapiHandle, 0, &wirelessStatus );
        }
        else {
            // nothing for us
            writeInProgress = NO;
        }

        if (error != NUR_NO_ERROR) {
            // failed to fetch tag
            [self showErrorMessage:error];
        }

        writeInProgress = NO;
    });
}

@end
