
#import <NurAPIBluetooth/Bluetooth.h>

#import "ReaderSettingsViewController.h"
#import "ConnectionManager.h"

enum {
    kHidBarcodeEnabled = 0,
    kHidRfidEnabled = 1,
    kWirelessChargingEnabled = 2,
} ReaderSettingType;


@interface ReaderSettingsViewController () {
    BOOL settingsRead;
    BOOL writeInProgress;
    NUR_ACC_CONFIG config;
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

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &config, sizeof(NUR_ACC_CONFIG) );

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != NUR_NO_ERROR) {
                [self showErrorMessage:error];
            }
            else {
                settingsRead = YES;
                [self.tableView reloadData];
            }
        });
    });
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Reader Settings", nil);
}


- (void) showErrorMessage:(int)error {
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReaderSettingCell" forIndexPath:indexPath];

    switch ( indexPath.section ) {
        case 0:
            switch ( indexPath.row ) {
                case kHidBarcodeEnabled:
                    cell.textLabel.text = NSLocalizedString(@"HID barcode", nil);
                    cell.accessoryType = config.flags & NUR_ACC_FL_HID_BARCODE ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;

                case kHidRfidEnabled:
                    cell.textLabel.text = NSLocalizedString(@"HID RFID", nil);
                    cell.accessoryType = config.flags & NUR_ACC_FL_HID_RFID ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
            }
            break;

        default:
            switch ( indexPath.row + kWirelessChargingEnabled) {
                case kWirelessChargingEnabled:
                    cell.textLabel.text = NSLocalizedString(@"Wireless charging (not used)", nil);
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
            }
    }
    
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( writeInProgress ) {
        NSLog( @"write in progress, skipping toggling data" );
        return;
    }

    if ( indexPath.section == 0 ) {
        switch ( indexPath.row ) {
            case kHidBarcodeEnabled:
                config.flags ^= NUR_ACC_FL_HID_BARCODE;
                break;

            case kHidRfidEnabled:
                config.flags ^= NUR_ACC_FL_HID_RFID;
                break;
        }
    }

    else {
        // handle wireless charging
    }

    [self saveSettings];

    // refresh
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


- (void) saveSettings {
    if ( writeInProgress ) {
        NSLog( @"write already in progress, skipping" );
        return;
    }

    writeInProgress = YES;

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurAccSetConfig( [Bluetooth sharedInstance].nurapiHandle, &config, sizeof(NUR_ACC_CONFIG) );
        if (error != NUR_NO_ERROR) {
            // failed to fetch tag
            [self showErrorMessage:error];
        }

        writeInProgress = NO;
    });
}

@end
