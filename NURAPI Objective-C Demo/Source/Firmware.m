
#import "Firmware.h"

@implementation Firmware

- (instancetype) initWithName:(NSString *)name version:(NSString *)version buildTime:(NSDate *)buildTime url:(NSURL *)url md5:(NSString *)md5 hw:(NSArray *)hw {
    self = [super init];
    if (self) {
        self.name = name;
        self.version = version;
        self.buildTime = buildTime;
        self.url = url;
        self.md5 = md5;
        self.hw = hw;
    }
    
    return self;
}
@end
