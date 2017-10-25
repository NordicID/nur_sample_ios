
#import "Firmware.h"

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
       // NSLog( @"%@ == %ld", self, (unsigned long)self.compareVersion );
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


+ (NSUInteger) calculateCompareVersion:(NSString *)version type:(FirmwareType)type {
    if ( type == kDeviceBootloader ) {
        return [version intValue];
    }

    int major, minor, build;

    if ( ! [Firmware extractMajor:&major minor:&minor build:&build fromVersion:version] ) {
        return 0;
    }

    //NSLog( @"version: %@, major: %d, minor: %d, build: %d", version, major, minor, build );
    return major * 1000000 + minor * 1000 + build;
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

    //NSLog( @"dot: %lu, dash: %lu", (unsigned long)dotLocation, (unsigned long)dashLocation );

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

@end
