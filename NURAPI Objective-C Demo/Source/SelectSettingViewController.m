
#import <NurAPIBluetooth/Bluetooth.h>

#import "SelectSettingViewController.h"
#import "SettingsAlternative.h"
#import "UIViewController+ErrorMessage.h"

@interface SelectSettingViewController () {
    // setup data
    struct NUR_MODULESETUP setup;
}
@end


@implementation SelectSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.title = self.settingName;
}


- (IBAction) save {
    // the antenna mask is handled differently
    if ( self.setting == NUR_SETUP_ANTMASKEX ) {
        DWORD antennaMask = 0;

        for ( SettingsAlternative * alternative in self.alternatives ) {
            if ( alternative.selected ) {
                antennaMask |= 1 << alternative.value;
            }
        }
        logDebug( @"save antenna mask: %u", antennaMask );

        // store the antenna mask in the setup struct
        setup.antennaMaskEx = antennaMask;
    }
    else {
        for ( SettingsAlternative * alternative in self.alternatives ) {
            if ( alternative.selected ) {
                logDebug( @"save setting '%@'", alternative.title );
                switch ( self.setting ) {
                    case NUR_SETUP_INVQ:
                        setup.inventoryQ = alternative.value;
                        break;

                    case NUR_SETUP_INVROUNDS:
                        setup.inventoryRounds = alternative.value;
                        break;

                    case NUR_SETUP_INVSESSION:
                        setup.inventorySession = alternative.value;
                        break;

                    case NUR_SETUP_INVTARGET:
                        setup.inventoryTarget = alternative.value;
                        break;

                    case NUR_SETUP_TXLEVEL:
                        setup.txLevel = alternative.value;
                        break;

                    case NUR_SETUP_LINKFREQ:
                        setup.linkFreq = alternative.value;
                        break;

                    case NUR_SETUP_REGION:
                        setup.regionId = alternative.value;
                        break;

                    case NUR_SETUP_AUTOTUNE:
                        setup.autotune.mode = alternative.value;

                        // TODO: this is hardcoded so far, taken from Android version
                        setup.autotune.threshold_dBm = -10;
                        break;
                        
                    case NUR_SETUP_RXDEC:
                        setup.rxDecoding = alternative.value;
                        break;
                        
                    case NUR_SETUP_RXSENS:
                        setup.rxSensitivity = alternative.value;
                        break;
                        
                    case NUR_SETUP_TXMOD:
                        setup.txModulation = alternative.value;
                        break;

                    default:
                        logError( @"invalid settings key: %d, not saving", self.setting );
                        return;
                }

                break;
            }
        }
    }


    // show a status popup that has no ok/cancel buttons, it's shown as long as the saving takes
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Saving", nil)
                                                                    message:NSLocalizedString(@"Saving setting to non volatile memory.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];


    // perform saving to volatile memory using the NURAPI dispatch queue
    dispatch_async(self.dispatchQueue, ^{
        int error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, self.setting, &setup, sizeof(struct NUR_MODULESETUP) );

        // if saved ok, store in non-volatile memory
        if ( error == NUR_NO_ERROR ) {
            error = NurApiStoreCurrentSetup([Bluetooth sharedInstance].nurapiHandle );
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // first always get rid of the status popup
            [alert dismissViewControllerAnimated:YES completion:^{
                if (error != NUR_NO_ERROR) {
                    [self showNurApiErrorMessage:error];
                }
                else {
                    logDebug( @"setting saved ok" );
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        });
    });
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.alternatives.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingAlternativeCell" forIndexPath:indexPath];

    SettingsAlternative * alternative = self.alternatives[ indexPath.row ];
    cell.textLabel.text = alternative.title;
    cell.accessoryType = alternative.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}


- (void) tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    logDebug( @"check row: %ld", (long)indexPath.row );

    // the antenna mask allows several to be set
    if ( self.setting == NUR_SETUP_ANTMASKEX ) {
        SettingsAlternative * alternative = self.alternatives[ indexPath.row ];
        alternative.selected = alternative.selected ? NO : YES;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }

    // first clear all alternatives
    for ( int row = 0; row < self.alternatives.count; ++row ) {
        SettingsAlternative * alternative = self.alternatives[ row ];
        if ( alternative.selected ) {
            // clear checkmark
            alternative.selected = NO;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }

    // set the new checked row
    SettingsAlternative * selected = self.alternatives[ indexPath.row ];
    selected.selected = YES;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
