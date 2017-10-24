
#import "ThemeManager.h"

@implementation ThemeManager

+ (ThemeManager *) sharedInstance {
    static ThemeManager * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[ThemeManager alloc] init];
    });

    // return the instance
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.theme = [Theme new];
    }

    return self;
}

@end
