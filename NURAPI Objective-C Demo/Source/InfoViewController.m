
#import <NurAPIBluetooth/Bluetooth.h>

#import "InfoViewController.h"

@interface InfoViewController () {
    struct NUR_READERINFO info;
    BOOL infoValid;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    infoValid = NO;

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_queue_create("com.nordicid.bluetooth-demo.nurapi-queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(self.dispatchQueue, ^{
        // get current settings
        int error = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != NUR_NO_ERROR) {
                // failed to fetch tag
                infoValid = NO;
                [self showErrorMessage:error];
            }
            else {
                infoValid = YES;
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


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! infoValid ) {
        return 0;
    }

    return 11;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];

    switch ( indexPath.row ) {
        case 0:
            cell.textLabel.text = @"Serial number";
            cell.detailTextLabel.text = [NSString stringWithCString:info.serial encoding:NSASCIIStringEncoding];
            break;

        case 1:
            cell.textLabel.text = @"Alt serial number";
            cell.detailTextLabel.text = [NSString stringWithCString:info.altSerial encoding:NSASCIIStringEncoding];
            break;

        case 2:
            cell.textLabel.text = @"Name";
            cell.detailTextLabel.text = [NSString stringWithCString:info.name encoding:NSASCIIStringEncoding];
            break;

        case 3:
            cell.textLabel.text = @"FCC id";
            cell.detailTextLabel.text = [NSString stringWithCString:info.fccId encoding:NSASCIIStringEncoding];
            break;

        case 4:
            cell.textLabel.text = @"Hardware version";
            cell.detailTextLabel.text = [NSString stringWithCString:info.hwVersion encoding:NSASCIIStringEncoding];
            break;

        case 5:
            cell.textLabel.text = @"Software version";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d.%d.%d", info.swVerMajor, info.swVerMinor, info.devBuild];
            break;

        case 6:
            cell.textLabel.text = @"Number of GPIO:s";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.numGpio];
            break;

        case 7:
            cell.textLabel.text = @"Number of sensors";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.numSensors];
            break;

        case 8:
            cell.textLabel.text = @"Number of regions";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.numRegions];
            break;

        case 9:
            cell.textLabel.text = @"Number of enabled antennas";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.numAntennas];
            break;

        case 10:
            cell.textLabel.text = @"Max number of antennas";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.maxAntennas];
            break;
    }

    return cell;
}

@end
