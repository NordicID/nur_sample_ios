
#import "Firmware.h"

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
    }
    
    return self;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"[name: '%@' type: %d version: %@, hw: %lu]", self.name, self.type, self.version, (unsigned long)self.hw.count];
}


- (BOOL) isNewerThanMajor:(int)major minor:(int)minor build:(int)build {
    NSRange range = [self.version rangeOfString:@"."];
    if ( range.length == 0 ) {
        // no dot found, can not compare
        return NO;
    }

    NSUInteger dotLocation = range.location;

    range = [self.version rangeOfString:@"-"];
    if ( range.length == 0 ) {
        // no dash found, can not compare
        return NO;
    }

    NSUInteger dashLocation = range.location;

    //NSLog( @"dot: %lu, dash: %lu", (unsigned long)dotLocation, (unsigned long)dashLocation );

    NSString * ownMajorStr = [self.version substringToIndex:dotLocation];
    NSString * ownMinorStr = [self.version substringWithRange:NSMakeRange(dotLocation +1, dashLocation - dotLocation - 1)];
    NSString * ownBuildStr = [self.version substringFromIndex:dashLocation + 1];
    //NSLog( @"major: %@, minor: %@, build: %@", ownMajorStr, ownMinorStr, ownBuildStr );

    int ownMajor = [ownMajorStr intValue];
    int ownMinor = [ownMinorStr intValue];
    char ownBuild = [ownBuildStr characterAtIndex:0] & 0xff;
    //NSLog( @"major: %d, minor: %d, build: %d %d", ownMajor, ownMinor, ownBuild, build );

    if ( ownMajor > major ) {
        return YES;
    }

    if ( ownMajor == major && ownMinor > minor ) {
        return YES;
    }

    if ( ownMajor == major && ownMinor == minor && ownBuild > build ) {
        return YES;
    }

    return NO;
}

@end
