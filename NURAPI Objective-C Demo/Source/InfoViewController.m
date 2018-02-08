
#import <NurAPIBluetooth/Bluetooth.h>

#import "InfoViewController.h"

@interface CellData : NSObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * value;

- (instancetype) initWithTitle:(NSString *)title value:(NSString *)value;
+ (instancetype) cellDataWithTitle:(NSString *)title value:(NSString *)value;

@end

@implementation CellData

- (instancetype) initWithTitle:(NSString *)title value:(NSString *)value {
    self = [super init];
    if (self) {
        self.title = title;
        self.value = value;
    }

    return self;
}

+ (instancetype) cellDataWithTitle:(NSString *)title value:(NSString *)value {
    return [[CellData alloc] initWithTitle:title value:value];
}


@end

enum {
    kSerialNumber,
    kAltSerialNumber,
    kName,
    kFccId,
    kHwVersion,
    kNurFirmwareVersion,
    kNurBootloaderVersion,
    kAccessoryFwVersion,

    kBatteryPercentage,
    kBatteryCapacity,

    kAccessoryName,
    kAccessoryHidRfid,
    kAccessoryHidBarcode,
} CellType;


@interface InfoViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSDictionary * cellData;

@end


@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // create the info data
    [self createCellData];

    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self.tableView reloadData];

        // prompt the user to connect a reader
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:NSLocalizedString(@"No RFID reader connected!", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Ok", nil)
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                              // nothing special to do right now
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_READERINFO info;
        NUR_ACC_BATT_INFO batteryInfo;
        NUR_ACC_CONFIG accessoryInfo;
        TCHAR accessoryFwVersionsTmp[32] = _T("");
        NSString * accessoryFwVersions;
        NSString * accessoryFwVersion;
        NSString * accessoryBootloaderVersion;
        TCHAR primaryVersionTmp[32] = _T("");
        TCHAR secondaryVersionTmp[32] = _T("");
        BYTE mode;
        NSString *primaryVersion, *secondaryVersion;

        // get current settings
        int error1 = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        int error2 = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));
        int error3 = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &accessoryInfo, sizeof(NUR_ACC_CONFIG));
        int error4 = NurAccGetFwVersion( [Bluetooth sharedInstance].nurapiHandle, accessoryFwVersionsTmp, 32);
        int error5 = NurApiGetVersions( [Bluetooth sharedInstance].nurapiHandle, &mode, primaryVersionTmp, secondaryVersionTmp );

        accessoryFwVersions = [NSString stringWithCString:accessoryFwVersionsTmp encoding:NSASCIIStringEncoding];

        primaryVersion   = [NSString stringWithCString:primaryVersionTmp encoding:NSASCIIStringEncoding];
        secondaryVersion = [NSString stringWithCString:secondaryVersionTmp encoding:NSASCIIStringEncoding];
        NSLog( @"primary version: %@", primaryVersion );
        NSLog( @"secondary version: %@", secondaryVersion );

        NSArray * parts = [accessoryFwVersions componentsSeparatedByString:@";"];
        if ( parts.count != 2 ) {
            // unexpected format, so use the entire string
            accessoryFwVersion = accessoryFwVersions;
        }
        else {
            // get the booloader version
            accessoryBootloaderVersion = [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            // now it is "2.1.4-H Oct 10 2017" or similar, get the version only and remove the date
            NSArray * parts2 = [parts[0] componentsSeparatedByString:@" "];
            if ( parts2.count > 0 ) {
                accessoryFwVersion = [parts2[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            else {
                // no space?
                accessoryFwVersion = parts[0];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error1 != NUR_NO_ERROR) {
                // failed to get info
                [self showErrorMessage:error1];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kSerialNumber) ]).value = [NSString stringWithCString:info.serial encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kAltSerialNumber) ]).value = [NSString stringWithCString:info.altSerial encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kName) ]).value = [NSString stringWithCString:info.name encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kFccId) ]).value = [NSString stringWithCString:info.fccId encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kHwVersion) ]).value = [NSString stringWithCString:info.hwVersion encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kNurFirmwareVersion) ]).value = [NSString stringWithFormat:@"%d.%d-%c", info.swVerMajor, info.swVerMinor, info.devBuild];
            }

            if (error2 != NUR_NO_ERROR) {
                // failed to get battery info
                [self showErrorMessage:error2];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kBatteryPercentage) ]).value = [NSString stringWithFormat:@"%d %%", batteryInfo.percentage];
                ((CellData *)self.cellData[ @(kBatteryCapacity) ]).value = [NSString stringWithFormat:@"%d", batteryInfo.cap_mA];
            }

            if (error3 != NUR_NO_ERROR) {
                // failed to get accessory info
                [self showErrorMessage:error3];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kAccessoryName) ]).value = [NSString stringWithCString:accessoryInfo.device_name encoding:NSASCIIStringEncoding];
                ((CellData *)self.cellData[ @(kAccessoryHidRfid) ]).value = accessoryInfo.flags & NUR_ACC_FL_HID_RFID ? NSLocalizedString(@"enabled", nil) : NSLocalizedString(@"disabled", nil);
                ((CellData *)self.cellData[ @(kAccessoryHidBarcode) ]).value = accessoryInfo.flags & NUR_ACC_FL_HID_BARCODE ? NSLocalizedString(@"enabled", nil) : NSLocalizedString(@"disabled", nil);
            }

            if (error4 != NUR_NO_ERROR) {
                // failed to get accessory version
                [self showErrorMessage:error4];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kAccessoryFwVersion) ]).value = accessoryFwVersion;
            }

            if (error5 != NUR_NO_ERROR) {
                // failed to get bootloader version
                [self showErrorMessage:error5];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kNurBootloaderVersion) ]).value = secondaryVersion;
            }

            [self.tableView reloadData];
        });
    });
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Info", nil);
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


- (void) createCellData {
    self.cellData = @{ @(kSerialNumber): [CellData cellDataWithTitle:NSLocalizedString(@"NUR serial number", nil) value:@"?"],
                       @(kAltSerialNumber):  [CellData cellDataWithTitle:NSLocalizedString(@"Device serial number", nil) value:@"?"],
                       @(kName): [CellData cellDataWithTitle:NSLocalizedString(@"NUR model", nil) value:@"?"],
                       @(kFccId): [CellData cellDataWithTitle:NSLocalizedString(@"FCC id", nil) value:@"?"],
                       @(kHwVersion): [CellData cellDataWithTitle:NSLocalizedString(@"Hardware version", nil) value:@"?"],

                       @(kNurFirmwareVersion): [CellData cellDataWithTitle:NSLocalizedString(@"NUR firmware", nil) value:@"?"],
                       @(kNurBootloaderVersion): [CellData cellDataWithTitle:NSLocalizedString(@"NUR bootloader", nil) value:@"?"],
                       @(kAccessoryFwVersion): [CellData cellDataWithTitle:NSLocalizedString(@"Device firmware", nil) value:@"?"],

                       @(kBatteryPercentage): [CellData cellDataWithTitle:NSLocalizedString(@"Percentage", nil) value:@"?"],
                       @(kBatteryCapacity): [CellData cellDataWithTitle:NSLocalizedString(@"Capacity (mA)", nil) value:@"?"],

                       @(kAccessoryName): [CellData cellDataWithTitle:NSLocalizedString(@"Name", nil) value:@"?"],
                       @(kAccessoryHidRfid): [CellData cellDataWithTitle:NSLocalizedString(@"RFID HID", nil) value:@"?"],
                       @(kAccessoryHidBarcode): [CellData cellDataWithTitle:NSLocalizedString(@"Barcode HID", nil) value:@"?"],
                       };
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"General information", nil);
        case 1:
            return NSLocalizedString(@"Battery status", nil);
        case 2:
            return NSLocalizedString(@"Accessory information", nil);
    }

    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 8;
        case 1:
            return 2;
        case 2:
            return 3;
    }
    
    // never called
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the data for our cell
    NSInteger key = indexPath.row;

    switch ( indexPath.section ) {
        case 1:
            key += kBatteryPercentage;
            break;
        case 2:
            key += kAccessoryName;
            break;
    }

    CellData * cellData = self.cellData[ @(key) ];

    // populate the cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
    cell.textLabel.text = cellData.title;
    cell.detailTextLabel.text = cellData.value;

    return cell;
}

@end
