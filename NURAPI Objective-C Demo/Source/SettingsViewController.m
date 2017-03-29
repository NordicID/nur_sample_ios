
#import <NurAPIBluetooth/Bluetooth.h>

#import "SettingsViewController.h"
#import "SettingsAlternative.h"
#import "SelectSettingViewController.h"
#import "TuneViewController.h"

// TODO:
//
// * read NUR_DEVICECAPS to see supported capabilities
// * enable physical antennas: NurApiEnablePhysicalAntenna


@interface SettingsViewController () {
    // setup data
    struct NUR_MODULESETUP setup;

    struct NUR_ANTENNA_MAPPING antennaMap[NUR_MAX_ANTENNAS_EX];
    int antennaMappingCount;

    struct NUR_DEVICECAPS deviceCaps;

    struct NUR_READERINFO readerInfo;

    struct NUR_REGIONINFO* regionInfo;

    // is all the data ready?
    BOOL dataReady;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation SettingsViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = @"Device Settings";

    dataReady = NO;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reading settings", nil)
                                                                    message:NSLocalizedString(@"Reading all settings from the device...", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_ALL, &setup, sizeof(struct NUR_MODULESETUP) );

        if ( error == NUR_NO_ERROR ) {
            // fetched ok, get antenna mask
            error = NurApiGetAntennaMap( [Bluetooth sharedInstance].nurapiHandle, antennaMap, &antennaMappingCount, NUR_MAX_ANTENNAS_EX, sizeof(struct NUR_ANTENNA_MAPPING) );

            NSLog( @"retrieved %d antenna mappings", antennaMappingCount );

            // region info
            if ( error == NUR_NO_ERROR ) {
                // the the number of regions and allocate space for them
                error = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &readerInfo, sizeof(struct NUR_READERINFO) );
                regionInfo = malloc( readerInfo.numRegions * sizeof( struct NUR_REGIONINFO ) );

                NSLog( @"retrieving %d region infos", readerInfo.numRegions );

                if ( error == NUR_NO_ERROR ) {
                    for ( unsigned int index = 0; index < readerInfo.numRegions; ++index ) {
                        error = NurApiGetRegionInfo( [Bluetooth sharedInstance].nurapiHandle, index, &regionInfo[ index ], sizeof( struct NUR_REGIONINFO) );

                        // finally get device capabilities
                        if ( error == NUR_NO_ERROR ) {
                            error = NurApiGetDeviceCaps( [Bluetooth sharedInstance].nurapiHandle, &deviceCaps );
                        }
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // now dismsis the "reading" popup and show and error or show the table
            [alert dismissViewControllerAnimated:YES completion:^{
                if (error != NUR_NO_ERROR) {
                    // failed to fetch tag
                    [self showErrorMessage:error];
                }
                else {
                    dataReady = YES;
                    [self.tableView reloadData];
                }
            }];
        });
    });
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


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // editing a settings requires
    if ( [segue.identifier isEqualToString:@"EditSettingSegue"] ) {
        SelectSettingViewController * destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

        // setup the alternatives available to the edit setting view controller
        [self setupAlternativesForRow:indexPath.row into:destination];
    }

//    else if ( [segue.identifier isEqualToString:@"TuneSegue"] ) {
//        TuneViewController * destination = [segue destinationViewController];
//        destination.dispatchQueue = self.dispatchQueue;
//        destination.antennaMask = setup.antennaMask;
//    }
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // data not yet loaded?
    if ( ! dataReady ) {
        return 0;
    }

    // match with the keys in cellForRowAtIndexPath
    return 12;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];

    int setupKeys[] = { NUR_SETUP_INVQ, NUR_SETUP_INVROUNDS, NUR_SETUP_INVSESSION, NUR_SETUP_INVTARGET,
        NUR_SETUP_TXLEVEL, NUR_SETUP_ANTMASKEX, NUR_SETUP_LINKFREQ, NUR_SETUP_REGION, NUR_SETUP_AUTOTUNE,
        NUR_SETUP_RXDEC, NUR_SETUP_RXSENS, NUR_SETUP_TXMOD };

    int key = setupKeys[ indexPath.row ];

    int enabledAntennaCount = 0;

    switch ( key ) {
        case NUR_SETUP_INVQ:
            cell.textLabel.text = NSLocalizedString(@"Q", nil);
            if ( setup.inventoryQ == 0 ) {
                cell.detailTextLabel.text = NSLocalizedString(@"Automatic", nil);
            }
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryQ];
            }
            break;

        case NUR_SETUP_INVROUNDS:
            cell.textLabel.text = NSLocalizedString(@"Rounds", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryRounds];
            break;

        case NUR_SETUP_INVSESSION:
            cell.textLabel.text = NSLocalizedString(@"Session", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventorySession];
            break;

        case NUR_SETUP_INVTARGET:
            cell.textLabel.text = NSLocalizedString(@"Target", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryTarget];
            break;

        case NUR_SETUP_TXLEVEL:
            cell.textLabel.text = NSLocalizedString(@"TX Level", nil);

            // 500 mW model?
            if ( deviceCaps.maxTxmW == 500 ) {
                cell.detailTextLabel.text = @[ @"27 dBm, 500mW", @"26 dBm, 398mW", @"25 dBm, 316mW", @"24 dBm, 251mW", @"23 dBm, 200mW",
                                               @"22 dBm, 158mW", @"21 dBm, 126mW", @"20 dBm, 100mW", @"19 dBm, 79mW",  @"18 dBm, 63mW",
                                               @"17 dBm, 50mW",  @"16 dBm, 40mW",  @"15 dBm, 32mW",  @"14 dBm, 25mW",  @"13 dBm, 20mW",
                                               @"12 dBm, 16mW",  @"11 dBm, 13mW",  @"10 dBm, 10mW",  @"9 dBm, 8mW",    @"8 dBm, 6mW"][ setup.txLevel ];
            }
            else {
                // 1000 mW
                cell.detailTextLabel.text = @[ @"30 dBm, 1000mW", @"29 dBm, 794mW", @"28 dBm, 631mW", @"27 dBm, 501mW", @"26 dBm, 398mW",
                                               @"25 dBm, 316mW",  @"24 dBm, 251mW", @"23 dBm, 200mW", @"22 dBm, 158mW", @"21 dBm, 126mW",
                                               @"20 dBm, 100mW",  @"19 dBm, 79mW",  @"18 dBm, 63mW",  @"17 dBm, 50mW",  @"16 dBm, 40mW",
                                               @"15 dBm, 32mW",   @"14 dBm, 25mW",  @"13 dBm, 20mW", @"12 dBm, 16mW",   @"11 dBm, 13mW"][ setup.txLevel ];
            }
            break;

            // not used
        case NUR_SETUP_ANTMASKEX:
            cell.textLabel.text = NSLocalizedString(@"Enabled Antennas", nil);

            // check the enabled antenna count. Each enabled bit is one enabled antenna
            for ( unsigned int index = 0; index < 32; ++index ) {
                if ( setup.antennaMaskEx & (1<<index) ) {
                    enabledAntennaCount++;
                }
            }

            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d antenna%@", nil), enabledAntennaCount, (enabledAntennaCount == 1 ? @"" : @"s")];
            break;

        case NUR_SETUP_LINKFREQ:
            cell.textLabel.text = NSLocalizedString(@"Link Frequency", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.linkFreq];
            break;

        case NUR_SETUP_REGION:
            cell.textLabel.text = NSLocalizedString(@"Region", nil);
            cell.detailTextLabel.text = [NSString stringWithCString:regionInfo[ setup.regionId ].name encoding:NSASCIIStringEncoding];
            break;

            // not used
        case NUR_SETUP_AUTOTUNE:
            cell.textLabel.text = NSLocalizedString(@"Autotune", nil);
            cell.detailTextLabel.text = @"";
            break;

        case NUR_SETUP_RXDEC:
            cell.textLabel.text = NSLocalizedString(@"RX decoding (Miller)", nil);
            cell.detailTextLabel.text = @[ @"FM-0", @"Miller-2", @"Miller-4", @"Miller-8"][ setup.rxDecoding ];
            break;

        case NUR_SETUP_RXSENS:
            cell.textLabel.text = NSLocalizedString(@"RX Sensitivity", nil);
            cell.detailTextLabel.text = @[ @"Nominal", @"Low", @"High"][ setup.rxSensitivity ];
            break;

        case NUR_SETUP_TXMOD:
            cell.textLabel.text = NSLocalizedString(@"TX modulation", nil);
            cell.detailTextLabel.text = @[ @"ASK",  @"PR-ASK"][ setup.txModulation ];
            break;

        default:
            cell.textLabel.text = NSLocalizedString(@"ERROR", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", key];
    }
    
    return cell;
}


//******************************************************************************************
#pragma mark - Alternatives

- (void) setupAlternativesForRow:(NSInteger)row into:(SelectSettingViewController *)destination {
    int setupKeys[] = { NUR_SETUP_INVQ, NUR_SETUP_INVROUNDS, NUR_SETUP_INVSESSION, NUR_SETUP_INVTARGET,
        NUR_SETUP_TXLEVEL, NUR_SETUP_ANTMASKEX, NUR_SETUP_LINKFREQ, NUR_SETUP_REGION, NUR_SETUP_AUTOTUNE,
        NUR_SETUP_RXDEC, NUR_SETUP_RXSENS, NUR_SETUP_TXMOD };

    NSMutableArray * alternatives = [NSMutableArray new];

    enum NUR_MODULESETUP_FLAGS key = setupKeys[ row ];

    switch ( key ) {
        case NUR_SETUP_INVQ:
            destination.settingName = @"Q";

            // 0-15, 0 == automatic
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:NSLocalizedString(@"Automatic", nil) value:0 selected:setup.inventoryQ == 0]];
            for ( int index = 1; index <= 15; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventoryQ == index]];
            }
        break;

        case NUR_SETUP_INVROUNDS:
            destination.settingName = NSLocalizedString(@"Inventory Rounds", nil);

            // 0-10
            for ( int index = 0; index <= 10; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventoryRounds == index]];
            }
            break;

        case NUR_SETUP_INVSESSION:
            destination.settingName = NSLocalizedString(@"Session", nil);

            // 0-3
            for ( int index = 0; index <= 3; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventorySession == index]];
            }
            break;

        case NUR_SETUP_INVTARGET:
            destination.settingName = NSLocalizedString(@"Inventory Target", nil);
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"A" value:NUR_INVTARGET_A selected:setup.inventoryTarget == NUR_INVTARGET_A]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"B" value:NUR_INVTARGET_B selected:setup.inventoryTarget == NUR_INVTARGET_B]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:NSLocalizedString(@"A or B", nil) value:NUR_INVTARGET_AB selected:setup.inventoryTarget == NUR_INVTARGET_AB]];
            break;

        case NUR_SETUP_TXLEVEL:
            destination.settingName = NSLocalizedString(@"TX Level", nil);

            if ( deviceCaps.maxTxmW == 500 ) {
                // 500 mW reader
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"27 dBm, 500mW" value:0  selected:setup.txLevel == 0]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"26 dBm, 398mW" value:1  selected:setup.txLevel == 1]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"25 dBm, 316mW" value:2  selected:setup.txLevel == 2]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"24 dBm, 251mW" value:3  selected:setup.txLevel == 3]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"23 dBm, 200mW" value:4  selected:setup.txLevel == 4]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"22 dBm, 158mW" value:5  selected:setup.txLevel == 5]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"21 dBm, 126mW" value:6  selected:setup.txLevel == 6]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"20 dBm, 100mW" value:7  selected:setup.txLevel == 7]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"19 dBm, 79mW"  value:8  selected:setup.txLevel == 8]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"18 dBm, 63mW"  value:9  selected:setup.txLevel == 9]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"17 dBm, 50mW"  value:10 selected:setup.txLevel == 10]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"16 dBm, 40mW"  value:11 selected:setup.txLevel == 11]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"15 dBm, 32mW"  value:12 selected:setup.txLevel == 12]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"14 dBm, 25mW"  value:13 selected:setup.txLevel == 13]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"13 dBm, 20mW"  value:14 selected:setup.txLevel == 14]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"12 dBm, 16mW"  value:15 selected:setup.txLevel == 15]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"11 dBm, 13mW"  value:16 selected:setup.txLevel == 16]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"10 dBm, 10mW"  value:17 selected:setup.txLevel == 17]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"9 dBm, 8mW"    value:18 selected:setup.txLevel == 18]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"8 dBm, 6mW"    value:19 selected:setup.txLevel == 19]];
            }
            else {
                // 1000 mW reader
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"30 dBm, 1000mW"value:0  selected:setup.txLevel == 0 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"29 dBm, 794mW" value:1  selected:setup.txLevel == 1 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"28 dBm, 631mW" value:2  selected:setup.txLevel == 2 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"27 dBm, 501mW" value:3  selected:setup.txLevel == 3 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"26 dBm, 398mW" value:4  selected:setup.txLevel == 4 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"25 dBm, 316mW" value:5  selected:setup.txLevel == 5 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"24 dBm, 251mW" value:6  selected:setup.txLevel == 6 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"23 dBm, 200mW" value:7  selected:setup.txLevel == 7 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"22 dBm, 158mW" value:8  selected:setup.txLevel == 8 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"21 dBm, 126mW" value:9  selected:setup.txLevel == 9 ]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"20 dBm, 100mW" value:10 selected:setup.txLevel == 10]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"19 dBm, 79mW"  value:11 selected:setup.txLevel == 11]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"18 dBm, 63mW"  value:12 selected:setup.txLevel == 12]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"17 dBm, 50mW"  value:13 selected:setup.txLevel == 13]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"16 dBm, 40mW"  value:14 selected:setup.txLevel == 14]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"15 dBm, 32mW"  value:15 selected:setup.txLevel == 15]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"14 dBm, 25mW"  value:16 selected:setup.txLevel == 16]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"13 dBm, 20mW"  value:17 selected:setup.txLevel == 17]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"12 dBm, 16mW"  value:18 selected:setup.txLevel == 18]];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"11 dBm, 13mW"  value:19 selected:setup.txLevel == 19]];
            }
            break;

        case NUR_SETUP_ANTMASKEX:
            destination.settingName = NSLocalizedString(@"Antennas", nil);

            for ( unsigned int index = 0; index < antennaMappingCount; ++index ) {
                int logicalAntennaId = antennaMap[ index ].antennaId;
                NSLog( @"id %d, %s", logicalAntennaId, antennaMap[ index ].name );
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithCString:antennaMap[ index ].name encoding:NSASCIIStringEncoding]
                                                                            value:index selected:setup.antennaMaskEx & (1<<index)]];
            }
            break;

        case NUR_SETUP_LINKFREQ:
            destination.settingName = NSLocalizedString(@"Link Frequency", nil);
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"160000 Hz" value:160000 selected:setup.linkFreq == 160000]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"256000 Hz" value:256000 selected:setup.linkFreq == 256000]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"320000 Hz" value:320000 selected:setup.linkFreq == 320000]];
            break;

        case NUR_SETUP_REGION:
            destination.settingName = NSLocalizedString(@"Region", nil);

            for ( unsigned int index = 0; index < readerInfo.numRegions; ++index ) {
                struct NUR_REGIONINFO info = regionInfo[ index ];
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithCString:info.name encoding:NSASCIIStringEncoding]
                                                                            value:index
                                                                         selected:setup.regionId == index]];
            }
            break;

        case NUR_SETUP_AUTOTUNE:
            // TODO
            break;

        case NUR_SETUP_RXDEC:
            destination.settingName = NSLocalizedString(@"RX Decoding", nil);
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"FM-0" value:0 selected:setup.rxDecoding == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-2" value:1 selected:setup.rxDecoding == 1]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-4" value:2 selected:setup.rxDecoding == 2]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-8" value:3 selected:setup.rxDecoding == 3]];
            break;

        case NUR_SETUP_RXSENS:
            destination.settingName = NSLocalizedString(@"RX Sensitivity", nil);
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:NSLocalizedString(@"Nominal", nil) value:0 selected:setup.rxSensitivity == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:NSLocalizedString(@"Low", nil) value:1 selected:setup.rxSensitivity == 1]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:NSLocalizedString(@"High", nil) value:2 selected:setup.rxSensitivity == 2]];
            break;

        case NUR_SETUP_TXMOD:
            destination.settingName = NSLocalizedString(@"RX Modulation", nil);
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"ASK" value:0 selected:setup.txModulation == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"PR-ASK" value:1 selected:setup.txModulation == 1]];
            break;

        default:
            // ignore
            break;
    }

    destination.setting = key;
    destination.alternatives = alternatives;
    destination.dispatchQueue = self.dispatchQueue;
}


@end
