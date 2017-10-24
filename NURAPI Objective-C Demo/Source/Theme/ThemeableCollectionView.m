
#import "ThemeableCollectionView.h"
#import "ThemeManager.h"

@implementation ThemeableCollectionView

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

    self.backgroundColor = theme.backgroundColor;
}

@end
