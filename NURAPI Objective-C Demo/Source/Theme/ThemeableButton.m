
#import "ThemeableButton.h"
#import "ThemeManager.h"

@implementation ThemeableButton

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

    self.backgroundColor = theme.primaryColor;
    [self setTitleColor:theme.lightTextColor forState:UIControlStateNormal];
}

@end
