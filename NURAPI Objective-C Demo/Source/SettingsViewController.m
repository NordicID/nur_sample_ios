
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

    struct NUR_READERINFO readerInfo;

    struct NUR_REGIONINFO* regionInfo;

    // is all the data ready?
    BOOL dataReady;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation SettingsViewController

- (void) viewDidLoad {
    dataReady = NO;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_queue_create("com.nordicid.bluetooth-demo.nurapi-queue", DISPATCH_QUEUE_SERIAL);

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
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != NUR_NO_ERROR) {
                // failed to fetch tag
                [self showErrorMessage:error];
            }
            else {
                dataReady = YES;
                [self.tableView reloadData];
            }
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
    UIAlertController * errorView = [UIAlertController alertControllerWithTitle:@"Error"
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:errorView animated:YES completion:nil];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // editing a settings requires
    if ( [segue.identifier isEqualToString:@"EditSettingSegue"] ) {
        SelectSettingViewController * destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

        // setup the alternatives available to the edit setting view controller
        [self setupAlternativesForRow:indexPath.row into:destination];
    }

    else if ( [segue.identifier isEqualToString:@"TuneSegue"] ) {
        TuneViewController * destination = [segue destinationViewController];
        destination.dispatchQueue = self.dispatchQueue;
        destination.antennaMask = setup.antennaMask;
    }
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
            cell.textLabel.text = @"Q";
            if ( setup.inventoryQ == 0 ) {
                cell.detailTextLabel.text = @"Automatic";
            }
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryQ];
            }
            break;

        case NUR_SETUP_INVROUNDS:
            cell.textLabel.text = @"Rounds";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryRounds];
            break;

        case NUR_SETUP_INVSESSION:
            cell.textLabel.text = @"Session";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventorySession];
            break;

        case NUR_SETUP_INVTARGET:
            cell.textLabel.text = @"Target";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryTarget];
            break;

        case NUR_SETUP_TXLEVEL:
            cell.textLabel.text = @"TX Level";
            cell.detailTextLabel.text = @[@"27 dBm, 500mW",@"26 dBm, 398mW",@"25 dBm, 316mW",@"24 dBm, 251mW",@"23 dBm, 200mW",
                                          @"22 dBm, 158mW",@"21 dBm, 126mW", @"20 dBm, 100mW",@"19 dBm, 79mW",@"18 dBm, 63mW",
                                          @"17 dBm, 50mW",@"16 dBm, 40mW",@"15 dBm, 32mW",@"14 dBm, 25mW",@"13 dBm, 20mW",
                                          @"12 dBm, 16mW",@"11 dBm, 13mW",@"10 dBm, 10mW",@"9 dBm, 8mW",@"8 dBm, 6mW"][ setup.txLevel ];
            break;

            // not used
        case NUR_SETUP_ANTMASKEX:
            cell.textLabel.text = @"Enabled Antennas";

            // check the enabled antenna count. Each enabled bit is one enabled antenna
            for ( unsigned int index = 0; index < 32; ++index ) {
                if ( setup.antennaMaskEx & (1<<index) ) {
                    enabledAntennaCount++;
                }
            }

            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d antenna%@", enabledAntennaCount, (enabledAntennaCount == 1 ? @"" : @"s")];
            break;

        case NUR_SETUP_LINKFREQ:
            cell.textLabel.text = @"Link Frequency";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.linkFreq];
            break;

        case NUR_SETUP_REGION:
            cell.textLabel.text = @"Region";
            cell.detailTextLabel.text = [NSString stringWithCString:regionInfo[ setup.regionId ].name encoding:NSASCIIStringEncoding];
            break;

            // not used
        case NUR_SETUP_AUTOTUNE:
            cell.textLabel.text = @"Autotune";
            cell.detailTextLabel.text = @"";
            break;

        case NUR_SETUP_RXDEC:
            cell.textLabel.text = @"RX decoding (Miller)";
            cell.detailTextLabel.text = @[ @"FM-0", @"Miller-2", @"Miller-4", @"Miller-8"][ setup.rxDecoding ];
            break;

        case NUR_SETUP_RXSENS:
            cell.textLabel.text = @"RX Sensitivity";
            cell.detailTextLabel.text = @[ @"Nominal", @"Low", @"High"][ setup.rxSensitivity ];
            break;

        case NUR_SETUP_TXMOD:
            cell.textLabel.text = @"TX modulation";
            cell.detailTextLabel.text = @[ @"ASK",  @"PR-ASK"][ setup.txModulation ];
            break;

        default:
            cell.textLabel.text = @"ERROR";
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
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Automatic" value:0 selected:setup.inventoryQ == 0]];
            for ( int index = 1; index <= 15; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventoryQ == index]];
            }
        break;

        case NUR_SETUP_INVROUNDS:
            destination.settingName = @"Inventory Rounds";

            // 0-10
            for ( int index = 0; index <= 10; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventoryRounds == index]];
            }
            break;

        case NUR_SETUP_INVSESSION:
            destination.settingName = @"Session";

            // 0-3
            for ( int index = 0; index <= 3; ++index ) {
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithFormat:@"%d", index] value:index selected:setup.inventorySession == index]];
            }
            break;

        case NUR_SETUP_INVTARGET:
            destination.settingName = @"Inventory Target";
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"A" value:NUR_INVTARGET_A selected:setup.inventoryTarget == NUR_INVTARGET_A]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"B" value:NUR_INVTARGET_B selected:setup.inventoryTarget == NUR_INVTARGET_B]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"A or B" value:NUR_INVTARGET_AB selected:setup.inventoryTarget == NUR_INVTARGET_AB]];
            break;

        case NUR_SETUP_TXLEVEL:
            destination.settingName = @"TX Level";

            // this assumes the 500mW version, different values for 1000mW reader. TODO: how to recognize?
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"27 dBm, 500mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"26 dBm, 398mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 1]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"25 dBm, 316mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 2]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"24 dBm, 251mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 3]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"23 dBm, 200mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 4]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"22 dBm, 158mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 5]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"21 dBm, 126mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 6]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"20 dBm, 100mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 7]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"19 dBm, 79mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 8]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"18 dBm, 63mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 9]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"17 dBm, 50mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 10]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"16 dBm, 40mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 11]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"15 dBm, 32mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 12]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"14 dBm, 25mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 13]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"13 dBm, 20mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 14]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"12 dBm, 16mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 15]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"11 dBm, 13mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 16]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"10 dBm, 10mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 17]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"9 dBm, 8mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 18]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"8 dBm, 6mW" value:NUR_SETUP_TXLEVEL selected:setup.txLevel == 19]];
            break;

        case NUR_SETUP_ANTMASKEX:
            destination.settingName = @"Antennas";

            for ( unsigned int index = 0; index < antennaMappingCount; ++index ) {
                int logicalAntennaId = antennaMap[ index ].antennaId;
                NSLog( @"id %d, %s", logicalAntennaId, antennaMap[ index ].name );
                [alternatives addObject:[SettingsAlternative alternativeWithTitle:[NSString stringWithCString:antennaMap[ index ].name encoding:NSASCIIStringEncoding]
                                                                            value:index selected:setup.antennaMaskEx & (1<<index)]];
            }
            break;

        case NUR_SETUP_LINKFREQ:
            destination.settingName = @"Link Frequency";
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"160000 Hz" value:160000 selected:setup.linkFreq == 160000]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"256000 Hz" value:256000 selected:setup.linkFreq == 256000]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"320000 Hz" value:320000 selected:setup.linkFreq == 320000]];
            break;

        case NUR_SETUP_REGION:
            destination.settingName = @"Region";

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
            destination.settingName = @"RX Decoding";
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"FM-0" value:0 selected:setup.rxDecoding == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-2" value:1 selected:setup.rxDecoding == 1]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-4" value:2 selected:setup.rxDecoding == 2]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Miller-8" value:3 selected:setup.rxDecoding == 3]];
            break;

        case NUR_SETUP_RXSENS:
            destination.settingName = @"RX Sensitivity";
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Nominal" value:0 selected:setup.rxSensitivity == 0]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"Low" value:1 selected:setup.rxSensitivity == 1]];
            [alternatives addObject:[SettingsAlternative alternativeWithTitle:@"High" value:2 selected:setup.rxSensitivity == 2]];
            break;

        case NUR_SETUP_TXMOD:
            destination.settingName = @"RX Modulation";
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


/*
 case NUR_SETUP_SCANSINGLETO:
 cell.textLabel.text = @"Single scan trigger timeout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.scanSingleTriggerTimeout];
 break;

 case NUR_SETUP_INVENTORYTO:
 cell.textLabel.text = @"Triggered inventory timeout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryTriggerTimeout];
 break;

 case NUR_SETUP_SELECTEDANT:
 cell.textLabel.text = @"Selected antenna";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.selectedAntenna];
 break;

 case NUR_SETUP_OPFLAGS:
 cell.textLabel.text = @"Operation flags";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.opFlags];
 break;

 case NUR_SETUP_INVEPCLEN:
 cell.textLabel.text = @"Inventory EPC length";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.inventoryEpcLength];
 break;

 // not used
 case NUR_SETUP_READRSSIFILTER:
 cell.textLabel.text = @"Read RSSI filter";
 cell.detailTextLabel.text = @"";
 break;

 // not used
 case NUR_SETUP_WRITERSSIFILTER:
 cell.textLabel.text = @"Write RSSI filter";
 cell.detailTextLabel.text = @"";
 break;

 // not used
 case NUR_SETUP_INVRSSIFILTER :
 cell.textLabel.text = @"Inventory RSSI filter";
 cell.detailTextLabel.text = @"";
 break;

 case NUR_SETUP_READTIMEOUT:
 cell.textLabel.text = @"Read timout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.readTO];
 break;

 case NUR_SETUP_WRITETIMEOUT:
 cell.textLabel.text = @"Write timout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.writeTO];
 break;

 case NUR_SETUP_LOCKTIMEOUT:
 cell.textLabel.text = @"Lock timeout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.lockTO];
 break;

 case NUR_SETUP_KILLTIMEOUT:
 cell.textLabel.text = @"Kill timeout";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.killTO];
 break;

 case NUR_SETUP_AUTOPERIOD:
 cell.textLabel.text = @"Auto period";
 cell.detailTextLabel.text = @[ @"Off", @"25% cycle", @"33% cycle", @"50% cycle"][ setup.periodSetup ];
 break;

 // not used
 case NUR_SETUP_PERANTPOWER:
 cell.textLabel.text = @"Tag";
 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", setup.readTO];
 break;

 // not used
 case NUR_SETUP_PERANTOFFSET:
 cell.textLabel.text = @"Tag";
 cell.detailTextLabel.text = @"";
 break;

 // not used
 case NUR_SETUP_PERANTPOWER_EX:
 cell.textLabel.text = @"Tag";
 cell.detailTextLabel.text = @"";
 break;
 */

@end