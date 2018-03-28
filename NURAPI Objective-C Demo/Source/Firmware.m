
#import "Firmware.h"
#import "Log.h"

@interface Firmware ()

@property (nonatomic, assign, readwrite) NSUInteger compareVersion;

@end


@implementation Firmware

- (instancetype) initWithName:(NSString *)name type:(FirmwareType)type version:(NSString *)version buildTime:(NSDate *)buildTime url:(NSURL *)url md5:(NSString *)md5 hw:(NSArray *)hw {
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
        self.version = version;
        self.buildTime = buildTime;
        self.url = url;
        self.md5 = md5;
        self.hw = hw;

        // set up the versin that allows firmwares to be compared
        self.compareVersion = [Firmware calculateCompareVersion:self.version type:self.type];
       // logDebug( @"%@ == %ld", self, (unsigned long)self.compareVersion );
    }
    
    return self;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"[name: '%@' type: %d version: %@, hw: %lu]", self.name, self.type, self.version, (unsigned long)self.hw.count];
}


+ (NSString *) getTypeString:(FirmwareType)type {
    switch ( type ) {
        case kNurFirmware:
            return NSLocalizedString(@"NUR firmware", @"section title in firmware selection screen");
            break;
        case kNurBootloader:
            return NSLocalizedString(@"NUR bootloader ", @"section title in firmware selection screen");
            break;
        case kDeviceFirmware:
            return NSLocalizedString(@"Device firmare", @"section title in firmware selection screen");
            break;
        case kDeviceBootloader:
            return NSLocalizedString(@"Device bootloader", @"section title in firmware selection screen");
            break;
    }

    // should never happen
    return @"INVALID";
}


- (BOOL) suitableForModel:(NSString *)model {
    logDebug( @"our model name: %@, suitable: %@", model, [self.hw componentsJoinedByString:@","]);
    return model != nil && [self.hw containsObject:model];
}


+ (NSUInteger) calculateCompareVersion:(NSString *)version type:(FirmwareType)type {
    if ( type == kDeviceBootloader ) {
        return [version intValue];
    }

    int major, minor, build, alpha = 0;

    if ( type == kDeviceFirmware ) {
        if ( ! [Firmware extractMajor:&major minor:&minor build:&build alpha:&alpha fromVersion:version] ) {
            return 0;
        }
    }

    else if ( ! [Firmware extractMajor:&major minor:&minor build:&build fromVersion:version] ) {
        return 0;
    }

    logDebug( @"version: %@, major: %d, minor: %d, build: %d, alpha: %d", version, major, minor, build, alpha );
    return major * 10000000 + minor * 100000 + build * 1000 + alpha;
}


+ (BOOL) extractMajor:(int *)major minor:(int *)minor build:(int *)build fromVersion:(NSString *)version {
    NSRange range = [version rangeOfString:@"."];
    if ( range.length == 0 ) {
        // no dot found
        return NO;
    }

    NSUInteger dotLocation = range.location;

    range = [version rangeOfString:@"-"];
    if ( range.length == 0 ) {
        // no dash found, not valid
        return NO;
    }

    NSUInteger dashLocation = range.location;

    //logDebug( @"dot: %lu, dash: %lu", (unsigned long)dotLocation, (unsigned long)dashLocation );

    // extract the version parts
    NSString * ownMajorStr = [version substringToIndex:dotLocation];
    NSString * ownMinorStr = [version substringWithRange:NSMakeRange(dotLocation +1, dashLocation - dotLocation - 1)];
    NSString * ownBuildStr = [version substringFromIndex:dashLocation + 1];

    *major = [ownMajorStr intValue];
    *minor = [ownMinorStr intValue];
    *build = [ownBuildStr characterAtIndex:0] & 0xff;

    // successfully converted
    return YES;
}


+ (BOOL) extractMajor:(int *)major minor:(int *)minor build:(int *)build alpha:(int *)alpha fromVersion:(NSString *)version {
    // the string is of the format: 1.2.3-A

    // replace all dashes with dots
    version = [version stringByReplacingOccurrencesOfString:@"-" withString:@"."];

    // split
    NSArray * parts = [version componentsSeparatedByString:@"."];
    if ( parts.count != 4 ) {
        return NO;
    }

    *major = [parts[0] intValue];
    *minor = [parts[1] intValue];
    *build = [parts[2] intValue];
    *alpha = [parts[3] characterAtIndex:0] & 0xff;

    // successfully converted
    return YES;
}

@end
