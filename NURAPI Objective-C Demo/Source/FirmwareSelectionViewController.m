
#import "FirmwareSelectionViewController.h"
#import "FirmwareCell.h"
#import "Firmware.h"
#import "PerformUpdateViewController.h"

@interface FirmwareSelectionViewController ()

@property (nonatomic, strong) NSArray * firmwares;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@end

#define FIRMWARE_URL @"https://raw.githubusercontent.com/NordicID/nur_firmware/master/firmwares.json"

@implementation FirmwareSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // a date formatter for nice dates in the cells
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    // start downloading the index file
    [self downloadIndexFile];
}


- (void) downloadIndexFile {
    NSString *dataUrl = FIRMWARE_URL;
    NSURL *url = [NSURL URLWithString:dataUrl];

    // create a download task for downloading the index file
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if ( error != nil ) {
                                                  NSLog( @"failed to download firmware index file");
                                                  [self showErrorMessage:@"Failed to download firmware update data!"];
                                                  return;
                                              }

                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                              if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                  if ( httpResponse ) {
                                                      NSLog( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                      [self showErrorMessage:[NSString stringWithFormat:@"Failed to download firmware update data, status code: %ld", (long)httpResponse.statusCode]];
                                                  }
                                                  else {
                                                      NSLog( @"failed to download firmware index file, no response" );
                                                      [self showErrorMessage:@"Failed to download firmware update data, no response received!"];
                                                  }

                                                  return;
                                              }

                                              // convert to a string an parse it
                                              NSString * json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              [self parseFirmwareIndexFile:json];
                                          }];
    
    // start the download
    [downloadTask resume];
}


- (void) parseFirmwareIndexFile:(NSString *)json {
    NSLog( @"parsing firmware index file: '%@'", json);

}


- (void) showErrorMessage:(NSString *)message {
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
