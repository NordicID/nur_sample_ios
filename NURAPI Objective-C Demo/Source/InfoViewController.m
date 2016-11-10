
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
    kSwVersion,

    kBatteryFlags,
    kBatteryPercentage,
    kBatteryVoltage,
    kBatteryCurrent,
    kBatteryCapacity,

    kAccessoryName,
    kAccessoryFwVersion,
} CellType;


@interface InfoViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSDictionary * cellData;

@end


@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = @"Info";

    // create the info data
    [self createCellData];

    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self.tableView reloadData];
        return;
    }

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_READERINFO info;
        NUR_ACC_BATT_INFO batteryInfo;
        NUR_ACC_CONFIG accessoryInfo;
        TCHAR accessoryFwVersionTmp[32] = _T("");
        NSString * accessoryFwVersion;

        // get current settings
        int error1 = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        int error2 = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));
        int error3 = NurAccGetConfig( [Bluetooth sharedInstance].nurapiHandle, &accessoryInfo, sizeof(NUR_ACC_CONFIG));
        int error4 = NurAccGetFwVersion( [Bluetooth sharedInstance].nurapiHandle, accessoryFwVersionTmp, 32);

        accessoryFwVersion = [NSString stringWithCString:accessoryFwVersionTmp encoding:NSASCIIStringEncoding];

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
                ((CellData *)self.cellData[ @(kSwVersion) ]).value = [NSString stringWithFormat:@"%d.%d.%d", info.swVerMajor, info.swVerMinor, info.devBuild];
            }

            if (error2 != NUR_NO_ERROR) {
                // failed to get battery info
                [self showErrorMessage:error2];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kBatteryFlags) ]).value = [NSString stringWithFormat:@"%x", batteryInfo.flags];
                ((CellData *)self.cellData[ @(kBatteryPercentage) ]).value = [NSString stringWithFormat:@"%d", batteryInfo.percentage];
                ((CellData *)self.cellData[ @(kBatteryVoltage) ]).value = [NSString stringWithFormat:@"%d", batteryInfo.volt_mV];
                ((CellData *)self.cellData[ @(kBatteryCurrent) ]).value = [NSString stringWithFormat:@"%d", batteryInfo.curr_mA];
                ((CellData *)self.cellData[ @(kBatteryCapacity) ]).value = [NSString stringWithFormat:@"%d", batteryInfo.cap_mA];
            }

            if (error3 != NUR_NO_ERROR) {
                // failed to get accessory info
                [self showErrorMessage:error3];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kAccessoryName) ]).value = [NSString stringWithCString:accessoryInfo.device_name encoding:NSASCIIStringEncoding];
            }

            if (error4 != NUR_NO_ERROR) {
                // failed to get accessory version
                [self showErrorMessage:error4];
            }
            else {
                // populate the cell data structures
                ((CellData *)self.cellData[ @(kAccessoryFwVersion) ]).value = accessoryFwVersion;
            }

            [self.tableView reloadData];
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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    // nothing special to do right now
                                }];


    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void) createCellData {
    self.cellData = @{ @(kSerialNumber): [CellData cellDataWithTitle:@"Serial number" value:@"?"],
                       @(kAltSerialNumber):  [CellData cellDataWithTitle:@"Alt serial number" value:@"?"],
                       @(kName): [CellData cellDataWithTitle:@"Name" value:@"?"],
                       @(kFccId): [CellData cellDataWithTitle:@"FCC id" value:@"?"],
                       @(kHwVersion): [CellData cellDataWithTitle:@"Hardware version" value:@"?"],
                       @(kSwVersion): [CellData cellDataWithTitle:@"Software version" value:@"?"],
                       @(kBatteryFlags): [CellData cellDataWithTitle:@"Flags" value:@"?"],
                       @(kBatteryPercentage): [CellData cellDataWithTitle:@"Percentage" value:@"?"],
                       @(kBatteryVoltage): [CellData cellDataWithTitle:@"Voltage (mV)" value:@"?"],
                       @(kBatteryCurrent): [CellData cellDataWithTitle:@"Current draw (mA)" value:@"?"],
                       @(kBatteryCapacity): [CellData cellDataWithTitle:@"Capacity (mA)" value:@"?"],
                       @(kAccessoryName): [CellData cellDataWithTitle:@"Name" value:@"?"],
                       @(kAccessoryFwVersion): [CellData cellDataWithTitle:@"Firmware version" value:@"?"],
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
            return @"General information";
        case 1:
            return @"Battery status";
        case 2:
            return @"Accessory information";
    }

    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 6;
        case 1:
            return 5;
        case 2:
            return 2;
    }
    
    // never called
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the data for our cell
    NSInteger key = indexPath.row;

    switch ( indexPath.section ) {
        case 1:
            key += kBatteryFlags;
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
