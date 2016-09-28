
#import "SettingsAlternative.h"

@implementation SettingsAlternative

- (instancetype) initWithTitle:(NSString *)title value:(int)value selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.title = title;
        self.value = value;
        self.selected = selected;
    }

    return self;
}


+ (instancetype) alternativeWithTitle:(NSString *)title value:(int)value selected:(BOOL)selected {
    return [[SettingsAlternative alloc] initWithTitle:title value:value selected:selected];
}

@end
