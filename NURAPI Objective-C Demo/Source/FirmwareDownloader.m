
#import "FirmwareDownloader.h"

@interface FirmwareDownloader()

@property (nonatomic, strong) NSDictionary * indexFileUrls;
@end


@implementation FirmwareDownloader

- (instancetype) initWithDelegate:(id<FirmwareDownloaderDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;

        self.indexFileUrls = @{ @(kNurFirmware): [NSURL URLWithString:@"https://raw.githubusercontent.com/NordicID/nur_firmware/master/firmwares.json"],
                                @(kNurBootloader): [NSURL URLWithString:@"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/firmwares.json"],
                                @(kDeviceFirmware): [NSURL URLWithString:@"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/Applicationfirmwares.json"],
                                @(kDeviceBootloader): [NSURL URLWithString:@"https://raw.githubusercontent.com/NordicID/nur_exa_firmware/master/Bootloaderfirmwares.json"] };
    }

    return self;
}


- (void) downloadIndexFiles {
    [self downloadIndexFile:kNurFirmware];
    [self downloadIndexFile:kNurBootloader];
    [self downloadIndexFile:kDeviceFirmware];
    [self downloadIndexFile:kDeviceBootloader];
}


- (void) downloadIndexFile:(FirmwareType)type {
    NSURL * url = self.indexFileUrls[ @(type) ];
    NSLog( @"downloading index file for firmware type: %d, url: %@", type, url );

    // create a download task for downloading the index file
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if ( error != nil ) {
                                                  NSLog( @"failed to download firmware index file");
                                                  if ( self.delegate ) {
                                                      [self.delegate firmwareMetaDataFailed:type error:NSLocalizedString(@"Failed to download firmware update data", nil)];
                                                  }
                                                  return;
                                              }

                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                              if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                  if ( httpResponse ) {
                                                      // a 404 means there is no such file, so no firmwares to download. This is not an error though
                                                      if ( httpResponse.statusCode == 404 ) {
                                                          if ( self.delegate ) {
                                                              [self.delegate firmwareMetaDataDownloaded:type firmwares:nil];
                                                          }
                                                      }
                                                      else {
                                                          NSLog( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          if ( self.delegate ) {
                                                              [self.delegate firmwareMetaDataFailed:type error:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                          }
                                                      }
                                                  }
                                                  else {
                                                      NSLog( @"failed to download firmware index file, no response" );
                                                      if ( self.delegate ) {
                                                          [self.delegate firmwareMetaDataFailed:type error:NSLocalizedString(@"Failed to download firmware update data, no response received!", nil)];
                                                      }
                                                  }

                                                  return;
                                              }

                                              // convert to a string an parse it
                                              [self parseIndexFile:type data:data];
                                          }];
    // start the download
    [downloadTask resume];
}


- (void) parseIndexFile:(FirmwareType)type data:(NSData *)data {
    NSError * error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ( error ) {
        NSLog( @"error parsing JSON: %@", error.localizedDescription );
        if ( self.delegate ) {
            [self.delegate firmwareMetaDataFailed:type error:[NSString stringWithFormat:NSLocalizedString(@"Failed to parse update data: %@", nil), error.localizedDescription]];
        }
        return;
    }

    NSLog( @"parsing firmware index file for type %d", type);
    NSMutableArray * foundFirmwares = [NSMutableArray new];

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

//        NSLog( @"name: %@, version: %@", name, version);
//        NSLog( @"url: %@, md5: %@", url, md5);
//        NSLog( @"buildTime: %@, stamp: %ld", buildTime, (unsigned long)buildTimestamp);

        NSMutableArray * validHw = [NSMutableArray new];

        // extract the suitable hardware
        for ( NSString * model in hw ) {
            [validHw addObject:model];
        }

        Firmware * firmware = [[Firmware alloc] initWithName:name  type:type version:version buildTime:buildTime url:url md5:md5 hw:validHw];
        [foundFirmwares addObject:firmware];
    }

    NSLog( @"loaded %lu firmwares", (unsigned long)foundFirmwares.count );

    // sort both so that we have the newest first
    [foundFirmwares sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Firmware * f1 = (Firmware *)obj1;
        Firmware * f2 = (Firmware *)obj2;
        return [f1.buildTime compare:f2.buildTime];
    }];

    if ( self.delegate ) {
        [self.delegate firmwareMetaDataDownloaded:type firmwares:foundFirmwares];
    }
}


@end
