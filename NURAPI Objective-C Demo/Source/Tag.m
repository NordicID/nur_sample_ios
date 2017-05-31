
#import "Tag.h"

@interface Tag ()

@property (nonatomic, strong, readwrite) NSString *  hex;
@property (nonatomic, assign, readwrite) DWORD       frequency;
@property (nonatomic, assign, readwrite) signed char rssi;
@property (nonatomic, assign, readwrite) DWORD       timestamp;
@property (nonatomic, assign, readwrite) BYTE        channel;
@property (nonatomic, assign, readwrite) BYTE        antennaId;
@property (nonatomic, strong, readwrite) NSDate *    firstFound;

@end


@implementation Tag

- (instancetype) initWithEpc:(NSData *)epc frequency:(DWORD)frequency rssi:(signed char)rssi scaledRssi:(char)scaledRssi timestamp:(DWORD)timestamp channel:(BYTE)channel antennaId:(BYTE)antennaId {
    self = [super init];
    if (self) {
        self.epc = epc;
        self.frequency = frequency;
        self.rssi = rssi;
        self.scaledRssi = scaledRssi;
        self.timestamp = timestamp;
        self.channel = channel;
        self.antennaId = antennaId;

        // we're found once now
        self.foundCount = 1;

        // found now
        self.firstFound = [NSDate date];
        self.lastFound = self.firstFound;
    }

    return self;
}


- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedString(@"<Tag %@>", nil), self.hex];
}


- (void) setEpc:(NSData *)epc {
    _epc = epc;

    const unsigned char *dataBuffer = (const unsigned char *)[self.epc bytes];

    if (!dataBuffer) {
        self.hex = [NSString string];
    }
    else {
        NSUInteger dataLength  = [self.epc length];
        NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];

        for (int index = 0; index < dataLength; ++index) {
            [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[index]]];
        }

        self.hex = [NSString stringWithString:hexString];
    }
}

@end
