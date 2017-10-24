
#import <NurAPIBluetooth/Bluetooth.h>

#import "FirmwareSelectionViewController.h"
#import "FirmwareCell.h"
#import "FirmwareSectionHeader.h"
#import "PerformUpdateViewController.h"

@interface FirmwareSelectionViewController ()

@property (nonatomic, strong) FirmwareDownloader * downloader;
@property (nonatomic, strong) dispatch_queue_t     dispatchQueue;
@property (nonatomic, strong) NSDateFormatter *    dateFormatter;
@property (nonatomic, strong) NSMutableArray *     allFirmwares;

@property (nonatomic, strong) NSMutableArray *     versionStrings;

@property (nonatomic, strong) NSString *           modelName;

@end


@implementation FirmwareSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self showErrorMessage:@"Please connect an RFID reader"];
        return;
    }

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    // register the section header NIB used in the table
    UINib * nib = [UINib nibWithNibName:@"FirmwareSectionHeader" bundle:nil];
    [self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"FirmwareSectionHeader"];

    // a date formatter for nice dates in the cells
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];

    // no firmwares yet
    self.allFirmwares = [NSMutableArray arrayWithObjects:
                         [NSArray new],
                         [NSArray new],
                         [NSArray new],
                         [NSArray new],
                         nil ];

    // default versions
    self.versionStrings = [NSMutableArray arrayWithObjects:
                           NSLocalizedString(@"unknown", @"firmware version unknown"),
                           NSLocalizedString(@"unknown", @"firmware version unknown"),
                           NSLocalizedString(@"unknown", @"firmware version unknown"),
                           NSLocalizedString(@"unknown", @"firmware version unknown"),
                           nil ];

    // downloader that handles getting the firmware index files and also the real firmwares
    self.downloader = [[FirmwareDownloader alloc] initWithDelegate:self];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Firmware Update", nil);

    // start by getting our model and version info
    [self fetchDeviceInformation];
}


- (void) fetchDeviceInformation {
    dispatch_async(self.dispatchQueue, ^{
        struct NUR_READERINFO info;
        TCHAR deviceVersionsTmp[32] = _T("");
        TCHAR primaryVersionTmp[32] = _T("");
        TCHAR secondaryVersionTmp[32] = _T("");
        BYTE mode;
        NSString * deviceVersions, *primaryVersion, *secondaryVersion;

        // get current settings
        NSLog( @"querying device versions" );
        int error1 = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        int error2 = NurAccGetFwVersion( [Bluetooth sharedInstance].nurapiHandle, deviceVersionsTmp, 32);
        int error3 = NurApiGetVersions( [Bluetooth sharedInstance].nurapiHandle, &mode, primaryVersionTmp, secondaryVersionTmp );

        deviceVersions   = [NSString stringWithCString:deviceVersionsTmp encoding:NSASCIIStringEncoding];
        primaryVersion   = [NSString stringWithCString:primaryVersionTmp encoding:NSASCIIStringEncoding];
        secondaryVersion = [NSString stringWithCString:secondaryVersionTmp encoding:NSASCIIStringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error1 != NUR_NO_ERROR) {
                // failed to get info
                [self.versionStrings setObject: NSLocalizedString( @"Error getting NUR firmware version", nil) atIndexedSubscript:kNurFirmware];
                [self showNurApiErrorMessage:error1];
            }
            else {
                self.modelName = [NSString stringWithCString:info.name encoding:NSASCIIStringEncoding];

                // version info
                int majorVersion = info.swVerMajor;
                int minorVersion = info.swVerMinor;
                char build = info.devBuild;
                [self.versionStrings setObject:[NSString stringWithFormat:@"%d.%d-%c", majorVersion, minorVersion, build] atIndexedSubscript:kNurFirmware];

                NSLog( @"our device model: %@", self.modelName );
                NSLog( @"current NUR firmware version: %@", self.versionStrings[kNurFirmware] );
            }

            if (error2 != NUR_NO_ERROR) {
                // failed to get accessory version
                [self.versionStrings setObject: NSLocalizedString( @"Error getting device firmware version", nil) atIndexedSubscript:kDeviceFirmware];
                [self showNurApiErrorMessage:error2];
            }
            else {
                NSArray * parts = [deviceVersions componentsSeparatedByString:@";"];
                if ( parts.count  != 2 ) {
                    [self.versionStrings setObject: NSLocalizedString( @"Unexpected device firmware version format", nil) atIndexedSubscript:kDeviceFirmware];
                    [self showNurApiErrorMessage:error2];
                }
                else {
                    NSString * deviceFirmwareVersion = [parts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString * deviceBootloaderVersion = [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                    [self.versionStrings setObject:deviceFirmwareVersion atIndexedSubscript:kDeviceFirmware];
                    [self.versionStrings setObject:deviceBootloaderVersion atIndexedSubscript:kDeviceBootloader];
                    NSLog( @"current device firmware version: '%@'", self.versionStrings[kDeviceFirmware] );
                    NSLog( @"current device bootloader version: '%@'", self.versionStrings[kDeviceBootloader] );
                }
            }

            if (error3 != NUR_NO_ERROR) {
                // failed to get accessory version
                [self.versionStrings setObject: NSLocalizedString( @"Error getting device firmware version", nil) atIndexedSubscript:kDeviceFirmware];
                [self showNurApiErrorMessage:error3];
            }
            else {
                NSLog( @"primary version: %@", primaryVersion );
                NSLog( @"secondary version: %@", secondaryVersion );
                [self.versionStrings setObject:secondaryVersion atIndexedSubscript:kNurBootloader];
            }

            // now start downloading the index file that we have all own versions
            [self.downloader downloadIndexFiles];
        });
    });
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
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


//*****************************************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! self.allFirmwares) {
        return 0;
    }

    NSArray * firmwares = self.allFirmwares[ section ];
    return firmwares.count;
}


- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    FirmwareSectionHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"FirmwareSectionHeader"];

    FirmwareType firmwareType = (FirmwareType)section;

    // do we have any available firmwares for this type?
    NSArray * firmwares = self.allFirmwares[ firmwareType ];
    if ( firmwares.count > 0 ) {
        header.statusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Updates available: %d", @"update status in firmware selection screen"), firmwares.count];
    }
    else {
        header.statusLabel.text = NSLocalizedString(@"No updates available", @"update status in firmware selection screen");
    }

    header.nameLabel.text = [Firmware getTypeString:firmwareType];
    header.versionLabel.text = [NSString stringWithFormat: NSLocalizedString(@"Current version: %@", @"current firmware version in firmware selection screen"), self.versionStrings[ firmwareType ]];
    return header;
}


- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // this is to be kept in sync with the view heigh in FirmwareSectionHeader.xib
    return 78;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the firmware
    NSArray * firmwares = self.allFirmwares[ indexPath.section ];
    Firmware * firmware = firmwares[ indexPath.row ];

    // instantiate the view controller
    PerformUpdateViewController * vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PerformUpdateViewController"];
    vc.firmware = firmware;

    // and show it
    [self.navigationController pushViewController:vc animated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FirmwareCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FirmwareCell" forIndexPath:indexPath];

    NSArray * firmwares = self.allFirmwares[ indexPath.section ];
    Firmware * firmware = firmwares[ indexPath.row ];

    cell.nameLabel.text = firmware.name;
    cell.versionLabel.text = firmware.version;
    cell.buildTimeLabel.text = [self.dateFormatter stringFromDate:firmware.buildTime];
    
    return cell;
}


//*****************************************************************************************************************
#pragma mark - Firmware downloader delegate

- (void) firmwareMetaDataDownloaded:(FirmwareType)type firmwares:(NSArray *)firmwares {
    NSLog( @"meta data downloaded for type: %d, firmwares found: %lu", type, (unsigned long)(firmwares != nil ? firmwares.count : 0));

    if ( firmwares == nil ) {
        return;
    }

    for ( Firmware * firmware in firmwares ) {
        NSLog( @"found firmware: %@", firmware );
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.allFirmwares[ type ] = firmwares;
        [self.tableView reloadData];
    } );
}


- (void) firmwareMetaDataFailed:(FirmwareType)type error:(NSString *)error {
    NSLog( @"meta data download failed for type: %d, error: %@", type, error );
}

@end
