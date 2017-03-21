
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

#define FIRMWARE_URL @"https://raw.githubusercontent.com/NordicID/nur_firmware/master/firmwares.json"

@implementation FirmwareSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // a date formatter for nice dates in the cells
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.modelName = @"INVALID";

    // start by getting our model
    [self fetchDeviceModel];
}


- (void) fetchDeviceModel {
    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_READERINFO info;

        // get current settings
        int error = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        if (error != NUR_NO_ERROR) {
            // failed to get info, extract the NURAPI error
            char buffer[256];
            NurApiGetErrorMessage( error, buffer, 256 );
            NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            [self showErrorMessage:[NSString stringWithFormat:@"Failed to query device info: %@", message]];
            return;
        }

        // extract the final model name
        self.modelName = [NSString stringWithCString:info.name encoding:NSASCIIStringEncoding];
        NSLog( @"our device model: %@", self.modelName );

        dispatch_async(dispatch_get_main_queue(), ^{
            // now start downloading the index file
            [self downloadIndexFile];
        } );
    });

}


- (void) downloadIndexFile {
    NSString *dataUrl = FIRMWARE_URL;
    NSURL *url = [NSURL URLWithString:dataUrl];

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:@"Downloading data"
                                                               message:@"Downloading available firmware updates, please wait."
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start downloading
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
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
                                                  [self parseFirmwareIndexFile:data];
                                              }];
        
        // start the download
        [downloadTask resume];
    }];
}


- (void) parseFirmwareIndexFile:(NSData *)data {
    NSError * error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ( error ) {
        NSLog( @"error parsing JSON: %@", error.localizedDescription );
        [self showErrorMessage:[NSString stringWithFormat:@"Failed to parse update data: %@", error.localizedDescription]];
        return;
    }

    NSLog( @"parsing firmware index file: '%@'", json);

    self.firmwares = [NSMutableArray new];

    for (NSMutableDictionary *firmwares in [json objectForKey:@"firmwares"]) {
        NSString *name = [firmwares objectForKey:@"name"];
        NSString *version = [firmwares objectForKey:@"version"];
        NSString *urlString = [firmwares objectForKey:@"url"];
        NSString *md5 = [firmwares objectForKey:@"md5"];
        NSUInteger buildTimestamp = [[firmwares objectForKey:@"buildtime"] longLongValue];
        NSArray * hw = [firmwares objectForKey:@"hw"];

        // convert the timestamp to a date
        NSDate * buildTime = [NSDate dateWithTimeIntervalSince1970:buildTimestamp];
        NSURL * url = [NSURL URLWithString:urlString];

        NSLog( @"name: %@, version: %@", name, version);
        NSLog( @"url: %@, md5: %@", url, md5);
        NSLog( @"buildTime: %@, stamp: %ld", buildTime, buildTimestamp);

        // is this a firmware for our model? check all the models
        for ( NSString * model in hw ) {
            if ( [self.modelName isEqualToString:model] ) {
                // set up the real firmware
                Firmware * firmware = [[Firmware alloc] initWithName:name version:version buildTime:buildTime url:url md5:md5 hw:hw];
                [self.firmwares addObject:firmware];

                // only add once
                break;
            }
        }
    }

    NSLog( @"loaded %lu firmwares", (unsigned long)self.firmwares.count );
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            [self dismissViewControllerAnimated:self.inProgressAlert completion:nil];
            self.inProgressAlert = nil;
        }

        [self.tableView reloadData];
    });
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self dismissViewControllerAnimated:self.inProgressAlert completion:nil];
            self.inProgressAlert = nil;
        }

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
