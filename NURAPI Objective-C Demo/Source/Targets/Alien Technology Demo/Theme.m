
#import "../../Theme/Theme.h"

@implementation Theme

- (instancetype)init {
    self = [super init];
    if (self) {
        // set up colors
        self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // white
        self.primaryColor    = [UIColor colorWithRed:163/255.0 green:38/255.0 blue:56/255.0 alpha:1]; // dark red
        self.secondaryColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // black
        self.lightTextColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // white
        self.darkTextColor   = [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // black

        // navigation bar
        [UINavigationBar appearance].barStyle = UIBarStyleBlack;
        [UINavigationBar appearance].translucent = NO;
        [UINavigationBar appearance].barTintColor = self.primaryColor;
        [UINavigationBar appearance].tintColor = self.lightTextColor;
        [UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName: self.lightTextColor };

        // textual theming
        self.applicationTitle = @"Alien Technology RFID";
    }

    return self;
}

@end
