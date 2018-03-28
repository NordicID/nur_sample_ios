
#import "FirmwareDownloader.h"
#import "Log.h"

@interface FirmwareDownloader()

@property (nonatomic, strong) NSDictionary * indexFileUrls;
@end


@implementation FirmwareDownloader

- (instancetype) initWithDelegate:(id<FirmwareDownloaderDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;

        // load the meta data plist from the bundle
        NSString* path = [[NSBundle mainBundle] pathForResource:@"MetaData" ofType:@"plist"];
        NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile: path];

        self.indexFileUrls = @{ @(kNurFirmware): [NSURL URLWithString:[metadata objectForKey:@"nurFirmwareIndexUrl"]],
                                @(kNurBootloader): [NSURL URLWithString:[metadata objectForKey:@"nurBootloaderIndexUrl"]],
                                @(kDeviceFirmware): [NSURL URLWithString:[metadata objectForKey:@"deviceFirmwareIndexUrl"]],
                                @(kDeviceBootloader): [NSURL URLWithString:[metadata objectForKey:@"deviceBootloaderIndexUrl"]]};
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
    logDebug( @"downloading index file for firmware type: %d, url: %@", type, url );

    // create a download task for downloading the index file
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if ( error != nil ) {
                                                  logError( @"failed to download firmware index file");
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
                                                          logError( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          if ( self.delegate ) {
                                                              [self.delegate firmwareMetaDataFailed:type error:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                          }
                                                      }
                                                  }
                                                  else {
                                                      logError( @"failed to download firmware index file, no response" );
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
        logError( @"error parsing JSON: %@", error.localizedDescription );
        if ( self.delegate ) {
            [self.delegate firmwareMetaDataFailed:type error:[NSString stringWithFormat:NSLocalizedString(@"Failed to parse update data: %@", nil), error.localizedDescription]];
        }
        return;
    }

    logDebug( @"parsing firmware index file for type %d", type);
    NSMutableArray * foundFirmwares = [NSMutableArray new];

    // testing
/*    if ( type == kNurFirmware ) {
        Firmware * firmware = [[Firmware alloc] initWithName:@"Test 1" type:kNurFirmware version:@"6.0-A" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 2" type:kNurFirmware version:@"4.0-A" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 3" type:kNurFirmware version:@"5.11-B" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 5" type:kNurFirmware version:@"6.10-B" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 6" type:kNurFirmware version:@"6.10-C" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 7" type:kNurFirmware version:@"6.11-D" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
        firmware = [[Firmware alloc] initWithName:@"Test 4" type:kNurFirmware version:@"5.11-C" buildTime:[NSDate date] url:[NSURL URLWithString:@"http://www.google.com"] md5:@"md5" hw:nil];
        [foundFirmwares addObject:firmware];
    }*/

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

        NSMutableArray * validHw = [NSMutableArray new];

        // extract the suitable hardware
        for ( NSString * model in hw ) {
            [validHw addObject:model];
        }

        Firmware * firmware = [[Firmware alloc] initWithName:name  type:type version:version buildTime:buildTime url:url md5:md5 hw:validHw];
        [foundFirmwares addObject:firmware];
    }

    logDebug( @"loaded %lu firmwares for type: %d", (unsigned long)foundFirmwares.count, type );

    // sort both so that we have the newest first
    [foundFirmwares sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Firmware * f1 = (Firmware *)obj1;
        Firmware * f2 = (Firmware *)obj2;
        if ( f1.compareVersion == f2.compareVersion ) {
            return NSOrderedSame;
        }

        return f1.compareVersion < f2.compareVersion ? NSOrderedDescending : NSOrderedAscending;
    }];

    if ( self.delegate ) {
        [self.delegate firmwareMetaDataDownloaded:type firmwares:foundFirmwares];
    }
}


@end
