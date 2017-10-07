
#import <NurAPIBluetooth/Bluetooth.h>

#import "FirmwareSelectionViewController.h"
#import "FirmwareCell.h"

@interface FirmwareSelectionViewController ()

@property (nonatomic, strong) FirmwareDownloader * downloader;
@property (nonatomic, strong) dispatch_queue_t     dispatchQueue;
@property (nonatomic, strong) NSDateFormatter *    dateFormatter;

@property (nonatomic, strong) NSMutableArray *     allFirmwares;

@end


@implementation FirmwareSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self showErrorMessage:@"Please connect an RFID reader"];
        return;
    }

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

    self.downloader = [[FirmwareDownloader alloc] initWithDelegate:self];
    [self.downloader downloadIndexFiles];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Firmware Update", nil);
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


//*****************************************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"NUR firmware", @"section title in firmware selection screen");
        case 1:
            return NSLocalizedString(@"NUR booloader ", @"section title in firmware selection screen");
        case 2:
            return NSLocalizedString(@"Device firmare", @"section title in firmware selection screen");
        case 3:
            return NSLocalizedString(@"Device booloader", @"section title in firmware selection screen");
    }

    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( ! self.allFirmwares) {
        return 0;
    }

    NSArray * firmwares = self.allFirmwares[ section ];
    return firmwares.count;
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
