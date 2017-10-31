
#import "../../Theme/Theme.h"

@implementation Theme

- (instancetype)init {
    self = [super init];
    if (self) {
        // set up colors
        self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // white
        self.primaryColor    = [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // black
        self.secondaryColor  = [UIColor colorWithRed:248/255.0 green:156/255.0 blue:27/255.0 alpha:1]; // orange
        self.lightTextColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // white
        self.darkTextColor   = [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // black

        // navigation bar
        [UINavigationBar appearance].barStyle = UIBarStyleBlack;
        [UINavigationBar appearance].translucent = NO;
        [UINavigationBar appearance].barTintColor = self.primaryColor;
        [UINavigationBar appearance].tintColor = self.lightTextColor;
        [UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName: self.lightTextColor };

        // textual theming
        self.applicationTitle = @"Nordic ID RFID";
    }

    return self;
}

@end
