
#import <NurAPIBluetooth/Bluetooth.h>

#import "FirmwareTypeViewController.h"
#import "PerformUpdateViewController.h"

@interface FirmwareTypeViewController () {
    int minorVersion;
    int majorVersion;
    int build;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@property (nonatomic, strong) UIAlertController * inProgressAlert;
@property (nonatomic, strong) NSString * readerModelName;
@property (nonatomic, strong) NSString * readerVersion;
@property (nonatomic, strong) NSString * nurRfidModelName;
@property (nonatomic, strong) NSString * nurRfidVersion;
@property (nonatomic, strong) NSMutableArray * readerFirmwares;
@property (nonatomic, strong) NSMutableArray * nurRfidFirmwares;

@property (nonatomic, strong) FirmwareDownloader * downloader;

@end


#define NUR_FIRMWARE_URL      @"https://raw.githubusercontent.com/NordicID/nur_firmware/master/firmwares.json"
#define NUR_BOOTLOADER_URL    @"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/firmwares.json"
#define DEVICE_FIRMWARE_URL   @"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/Applicationfirmwares.json<"
#define DEVICE_BOOTLOADER_URL @"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/Bootloaderfirmwares.json"


@implementation FirmwareTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    minorVersion = -1;
    majorVersion = -1;
    build = -1;

    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self showErrorMessage:@"Please connect an RFID reader"];
        return;
    }

    // a date formatter for nice dates in the cells
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.readerModelName = @"INVALID";
    self.nurRfidModelName = @"INVALID";

    self.downloader = [[FirmwareDownloader alloc] initWithDelegate:self];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Firmware Update", nil);

    // start by getting our model
    [self fetchDeviceInformation];
}


- (void) fetchDeviceInformation {
    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    dispatch_async(self.dispatchQueue, ^{
        struct NUR_READERINFO info;
        TCHAR accessoryFwVersionTmp[32] = _T("");
        NSString * accessoryFwVersion;

        // get current settings
        int error1 = NurApiGetReaderInfo( [Bluetooth sharedInstance].nurapiHandle, &info, sizeof(struct NUR_READERINFO) );
        int error2 = NurAccGetFwVersion( [Bluetooth sharedInstance].nurapiHandle, accessoryFwVersionTmp, 32);
        accessoryFwVersion = [NSString stringWithCString:accessoryFwVersionTmp encoding:NSASCIIStringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error1 != NUR_NO_ERROR) {
                // failed to get info
                self.currentNurRfidFirmwareVersion.text = NSLocalizedString( @"Error getting NUR RFID firmware version", nil);
                [self showNurApiErrorMessage:error1];
            }
            else {
                self.nurRfidModelName = [NSString stringWithCString:info.name encoding:NSASCIIStringEncoding];

                // version info
                majorVersion = info.swVerMajor;
                minorVersion = info.swVerMinor;
                build = info.devBuild;
                self.nurRfidVersion = [NSString stringWithFormat:@"%d.%d-%c", majorVersion, minorVersion, build];
                self.currentNurRfidFirmwareVersion.text = self.nurRfidVersion;

                NSLog( @"our device model: %@", self.nurRfidModelName );
                NSLog( @"current NUR RFID version: %@", self.nurRfidVersion );
            }

            if (error2 != NUR_NO_ERROR) {
                // failed to get accessory version
                self.currentReaderFirmwareVersion.text = NSLocalizedString( @"Error getting reader firmware version", nil);
                [self showNurApiErrorMessage:error2];
            }
            else {
                // populate the cell data structures
                self.readerVersion = accessoryFwVersion;
                self.currentReaderFirmwareVersion.text = self.readerVersion;
                NSLog( @"current reader version: %@", self.readerVersion );
            }
        });


        dispatch_async(dispatch_get_main_queue(), ^{
            // now start downloading the index file
            [self.downloader downloadIndexFiles];
            //[self downloadIndexFile];
        } );
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


- (void) downloadIndexFile {
    NSString *dataUrl = NUR_FIRMWARE_URL;
    NSURL *url = [NSURL URLWithString:dataUrl];

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Downloading data", nil)
                                                               message:NSLocalizedString(@"Downloading available firmware updates, please wait.", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start downloading
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        // create a download task for downloading the index file
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                              dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                  if ( error != nil ) {
                                                      NSLog( @"failed to download firmware index file");
                                                      [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data!", nil)];
                                                      return;
                                                  }

                                                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                  if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                      if ( httpResponse ) {
                                                          NSLog( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          [self showErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                      }
                                                      else {
                                                          NSLog( @"failed to download firmware index file, no response" );
                                                          [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data, no response received!", nil)];
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
        [self showErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to parse update data: %@", nil), error.localizedDescription]];
        return;
    }

    NSLog( @"parsing firmware index file: '%@'", json);

    self.readerFirmwares = [NSMutableArray new];
    self.nurRfidFirmwares = [NSMutableArray new];

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
        NSLog( @"buildTime: %@, stamp: %ld", buildTime, (unsigned long)buildTimestamp);

        // is this a firmware for our model? check all the models
        for ( NSString * model in hw ) {
            NSLog( @"cheking model: %@", model );
            if ( [self.readerModelName isEqualToString:model] ) {
                NSLog( @"found reader firmware" );
                //Firmware * firmware = [[Firmware alloc] initWithName:name version:version buildTime:buildTime url:url md5:md5 type:kNurFirmware];
                //[self.readerFirmwares addObject:firmware];
            }
            else if ( [self.nurRfidModelName isEqualToString:model] ) {
                NSLog( @"found NurRFID firmware" );
                //Firmware * firmware = [[Firmware alloc] initWithName:name version:version buildTime:buildTime url:url md5:md5 type:kNurBootloader];
                //[self.nurRfidFirmwares addObject:firmware];
            }
            else {
                NSLog( @"firmware not for our device" );
                continue;
            }

            // only add once
            break;
        }
    }

    NSLog( @"loaded %lu reader firmwares", (unsigned long)self.readerFirmwares.count );
    NSLog( @"loaded %lu NurRFID firmwares", (unsigned long)self.nurRfidFirmwares.count );

    // sort both so that we have the newest first
    [self.readerFirmwares sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Firmware * f1 = (Firmware *)obj1;
        Firmware * f2 = (Firmware *)obj2;
        return [f1.buildTime compare:f2.buildTime];
    }];

    [self.nurRfidFirmwares sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Firmware * f1 = (Firmware *)obj1;
        Firmware * f2 = (Firmware *)obj2;
        return [f1.buildTime compare:f2.buildTime];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            self.inProgressAlert = nil;
        }

        self.readerFirmwareButton.enabled = NO;
        self.nurRfidFirmwareButton.enabled = NO;

        // find the newest reader firmware
        if ( self.readerFirmwares.count > 0 ) {
            Firmware * newest = [self.readerFirmwares lastObject];

            // TODO: is it newer that our?
            self.availableReaderFirmwareVersion.text = newest.version;
            self.readerFirmwareButton.enabled = YES;
        }
        else {
            self.availableReaderFirmwareVersion.text = @"No update available";
        }

        // find the newest NUR RFID firmware
        if ( self.nurRfidFirmwares.count > 0 ) {
            Firmware * newest = [self.nurRfidFirmwares lastObject];

            // is it newer that our?
            if ( ! [newest isNewerThanMajor:majorVersion minor:minorVersion build:build] ) {
                self.availableNurRfidFirmwareVersion.text = @"Newest version already installed";
            }
            else {
                self.availableNurRfidFirmwareVersion.text = newest.version;
                self.nurRfidFirmwareButton.enabled = YES;
            }
        }
        else {
            self.availableNurRfidFirmwareVersion.text = @"No update available";
        }
    });
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PerformUpdateViewController * destination = [segue destinationViewController];

    if ( [segue.identifier isEqualToString:@"NurRFIDFirmwareUpdateSegue"] ) {
        destination.firmware = [self.nurRfidFirmwares lastObject];
    }
    else if ( [segue.identifier isEqualToString:@"ReaderFirmwareUpdateSegue"] ) {
        destination.firmware = [self.readerFirmwares lastObject];
    }
}


//*****************************************************************************************************************
#pragma mark - Firmware downloader delegate

- (void) firmwareMetaDataDownloaded:(FirmwareType)type firmwares:(NSArray *)firmwares {
    NSLog( @"meta data downloaded for type: %d, firmwares found: %lu", type, (unsigned long)(firmwares != nil ? firmwares.count : 0));

    for ( Firmware * firmware in firmwares ) {
        NSLog( @"found firmware: %@", firmware );
    }
}


- (void) firmwareMetaDataFailed:(FirmwareType)type error:(NSString *)error {
    NSLog( @"meta data download failed for type: %d, error: %@", type, error );
}

@end
