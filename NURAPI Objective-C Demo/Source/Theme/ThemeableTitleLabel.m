
#import "ThemeableTitleLabel.h"
#import "ThemeManager.h"

@implementation ThemeableTitleLabel

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

    //self.backgroundColor = theme.backgroundColor;
    self.textColor = theme.secondaryColor;
}

@end
