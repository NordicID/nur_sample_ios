
#import "ThemeableTabBar.h"
#import "ThemeManager.h"

@implementation ThemeableTabBar

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupTheme];
    }

    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupTheme];
    }

    return self;
}


- (void) setupTheme {
    Theme * theme = [ThemeManager sharedInstance].theme;

    self.barTintColor = theme.primaryColor;
    self.tintColor = theme.secondaryColor;
}

@end
