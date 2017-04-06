
#import <NurAPIBluetooth/Bluetooth.h>

#import "FirmwareSelectionViewController.h"
#import "FirmwareCell.h"
#import "Firmware.h"
#import "PerformUpdateViewController.h"

@interface FirmwareSelectionViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSMutableArray * firmwares;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@property (nonatomic, strong) UIAlertController * inProgressAlert;
@property (nonatomic, strong) NSString * modelName;

@end


@implementation FirmwareSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // a date formatter for nice dates in the cells
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.modelName = @"INVALID";

    // start by getting our model
    //   [self fetchDeviceModel];
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            self.inProgressAlert = nil;
        }

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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! self.firmwares ) {
        // nothing yet downloaded
        return 0;
    }

    return self.firmwares.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FirmwareCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FirmwareCell" forIndexPath:indexPath];

    Firmware * firmware = self.firmwares[ indexPath.row ];

    cell.nameLabel.text = firmware.name;
    cell.versionLabel.text = firmware.version;
    cell.buildTimeLabel.text = [self.dateFormatter stringFromDate:firmware.buildTime];

    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"PerformUpdateSegue"] ) {
        PerformUpdateViewController * destination = [segue destinationViewController];

        NSIndexPath *indexPath = [sender isKindOfClass:[NSIndexPath class]] ? (NSIndexPath*)sender : [self.tableView indexPathForSelectedRow];

        // let the VC know of the firmware it should be flashing
        destination.firmware = self.firmwares[ indexPath.row ];
    }
}

@end
